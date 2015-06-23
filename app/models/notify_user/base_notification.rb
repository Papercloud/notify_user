require 'aasm'
require 'sidekiq'

module NotifyUser
  class BaseNotification < ActiveRecord::Base
    require 'cgi'
    include ActionView::Helpers::TextHelper
    include AASM

    after_commit :deliver!, on: :create
    after_commit :deliver, on: :create

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :params, :target, :type, :state
    end

    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

    #checks if user has unsubscribed from this notif type
    validate :unsubscribed_validation

    # Params for creating the notification message.
    if ActiveRecord::VERSION::MAJOR < 4
      serialize :params, JSON
    end

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type, :state
    validate :presence_of_target_id

    aasm column: :state do

      # Created, not sent yet. Possibly waiting for aggregation.
      state :pending, initial: true

      # Delivers without aggregation
      state :pending_no_aggregation

      # Email/SMS/APNS has been sent.
      state :sent

      # Identifies which notification within the aggregation window that was actually delayed
      state :sent_as_aggregation_parent
      state :pending_as_aggregation_parent

      # The user has seen this notification.
      state :read

      # Record that we have sent message(s) to the user about this notification.
      event :mark_as_sent do
        transitions from: [:pending_as_aggregation_parent], to: :sent_as_aggregation_parent, :if => :pending_as_aggregation_parent?
        transitions from: [:pending, :pending_no_aggregation], to: :sent, :unless => :pending_as_aggregation_parent?
        after do
          self.sent_time = Time.now
          self.save
        end
      end

      event :mark_as_sent_as_aggregation_parent do
        transitions from: [:pending_as_aggregation_parent], to: :sent_as_aggregation_parent

      end

      event :mark_as_pending_as_aggregation_parent do
        transitions from: [:pending], to: :pending_as_aggregation_parent
      end

      event :dont_aggregate do
        transitions from: :pending, to: :pending_no_aggregation
      end

      # Record that the user has seen this notification, usually on a page or in the app.
      # A notification can go straight from pending to read if it's seen in a view before
      # sent in an email.
      event :mark_as_read do
        transitions from: [:pending, :sent, :sent_as_aggregation_parent], to: :read
      end
    end

    def params
      if super.nil?
        {}
      else
        super.with_indifferent_access
      end
    end

    # returns the global unread notification count for a user
    def count_for_target
      NotifyUser::BaseNotification.for_target(target).where('state IN (?)', ["sent", "pending"]).count
    end

    def message
      string = ActionView::Base.new(
             Rails.configuration.paths["app/views"]).render(
             :template => self.class.views[:mobile_sdk][:template_path].call(self), :formats => [:html],
             :locals => { :params => self.params})

      return ::CGI.unescapeHTML("#{string}")
    end

    def mobile_message(length=115)
      string = truncate(ActionView::Base.new(
             Rails.configuration.paths["app/views"]).render(
             :template => self.class.views[:mobile_sdk][:template_path].call(self), :formats => [:html],
             :locals => { :params => self.params}), :length => length)

      return ::CGI.unescapeHTML("#{string}")
    end

    ## Public Interface
    def to(user)
      self.target = user
      self
    end

    def with(*args)
      self.params = args.reduce({}, :update)
      self
    end

    def notify!
      # Bang version of 'notify' ignores aggregation
      dont_aggregate!
    end

    # Send any Emails/SMS/APNS
    def notify
      # Sends with aggregation if enabled
      save
    end

    def generate_unsubscribe_hash
      #check if a hash already exists for that user otherwise create a new one
      return NotifyUser::UserHash.where(target_id: self.target.id).where(target_type: self.target.class.base_class).where(type: self.type).where(active: true).first || NotifyUser::UserHash.create(target: self.target, type: self.type, active: true)
    end

    def aggregation_interval
      sent_aggregation_parents.count
    end

    def delay_time(options)
      a_interval = options[:aggregate_per][aggregation_interval]
      # last sent notification
      last_sent_parent = sent_aggregation_parents.first
      # Uses the time of the last notification sent otherwise will send it now.
      delay_time = last_sent_parent ? last_sent_parent.sent_time : created_at

      # If this is the first notification the aggregate interval will return 0. Thus sending the notification now!
      return delay_time + a_interval.minutes
    end

    def sent_aggregation_parents
      self.class
        .for_target(self.target)
        .where(state: :sent_as_aggregation_parent)
        .where("params->>'group_id' = ?", params[:group_id].to_s)
        .order(created_at: :desc)
    end

    ## Notification description
    class_attribute :description
    self.description = ""

    ## Channels
    class_attribute :channels
    self.channels = {
    }

    # Not sure about this. The JSON and web feeds don't fit into channels, because nothing is broadcast through
    # them. Not sure if they really need another concept though, they could just be formats on the controller.
    class_attribute :views
    self.views = {
      mobile_sdk: {
        template_path: Proc.new {|n| "notify_user/#{n.class.name.underscore}/mobile_sdk/notification" }
      }
    }

    # Configure a channel
    def self.channel(name, options={})
      channels_clone = self.channels.clone
      channels_clone[name] = options
      self.channels = channels_clone
    end

    ## Aggregation

    class_attribute :aggregate_per
    self.aggregate_per = 1.minute

    ## Sending

    def self.for_target(target)
      where(target_id: target.id)
      .where(target_type: target.class.base_class)
    end

    def self.pending_aggregation_with(notification)
      where(type: notification.type)
      .for_target(notification.target)
      .where(state: :pending_as_aggregation_parent)
    end

    def aggregation_pending?
      # A notification of the same type, that would have an aggregation job associated with it,
      # already exists.
      return (self.class.pending_aggregation_with(self).where('id != ?', id).count > 0)
    end

    # Aggregates appropriately
    def deliver
      if pending? and not user_has_unsubscribed?

        # if aggregation is false bypass aggregation completely
        self.channels.each do |channel_name, options|
          if(options[:aggregate_per] == false)
            self.mark_as_sent!
            self.class.delay.deliver_notification_channel(self.id, channel_name)
          else
            # only notifies channels if no pending aggregate notifications
            if not aggregation_pending?
              self.mark_as_pending_as_aggregation_parent!
              # adds fallback support for integer or array of integers
              if options[:aggregate_per].kind_of?(Array)
                self.class.delay_until(delay_time(options)).notify_aggregated_channel(self.id, channel_name)
              else
                a_interval = options[:aggregate_per] || self.aggregate_per
                self.class.delay_for(a_interval).notify_aggregated_channel(self.id, channel_name)
              end

            end
          end
        end
      end
    end

    # Sends immediately and without aggregation
    def deliver!
      if pending_no_aggregation? and not user_has_unsubscribed?
        self.mark_as_sent!
        self.class.deliver_channels(self.id)
      end
    end

    # Deliver a single notification across each channel.
    def self.deliver_channels(notification_id)
      self.channels.each do |channel_name, options|
        self.deliver_notification_channel(notification_id, channel_name)
      end
    end

    # Deliver multiple notifications across each channel as an aggregate message.
    def self.deliver_channels_aggregated(notifications)
      self.channels.each do |channel_name, options|
          if options[:aggregate_per] != false && !unsubscribed_from_channel?(notifications.first.target, channel_name)
            channel = (channel_name.to_s + "_channel").camelize.constantize
            channel.deliver_aggregated(notifications, options)
          end
      end
    end

    #deliver to specific channel methods

    # Deliver a single notification to a specific channel.
    def self.deliver_notification_channel(notification_id, channel_name)
      notification = self.find(notification_id) # Raise an exception if not found.

      channel_options = channels[channel_name.to_sym]
      channel = (channel_name.to_s + "_channel").camelize.constantize

      unless self.unsubscribed_from_channel?(notification.target, channel_name)
        channel.deliver(notification, channel_options)
      end
    end

    # Deliver a aggregated notifications to a specific channel.
    def self.deliver_notifications_channel(notifications, channel_name)
      channel_options = channels[channel_name.to_sym]
      channel = (channel_name.to_s + "_channel").camelize.constantize

      #check if user unsubsribed from channel type
      unless self.unsubscribed_from_channel?(notifications.first.target, channel_name)
        channel.deliver_aggregated(notifications, channel_options)
      end
    end

    # Prepares a single channel for aggregation
    def self.notify_aggregated_channel(notification_id, channel_name)
      notification = self.find(notification_id) # Raise an exception if not found.

      # Find any pending notifications with the same type and target, which can all be sent in one message.
      notifications = self.pending_aggregation_with(notification)

      notifications.map(&:mark_as_sent)
      notifications.map(&:save)

      return if notifications.empty?
      if notifications.length == 1
        # Despite waiting for more to aggregate, we only got one in the end.
        self.deliver_notification_channel(notifications.first.id, channel_name)
      else
        # We got several notifications while waiting, send them aggregated.
        self.deliver_notifications_channel(notifications, channel_name)
      end
    end

    private

    def presence_of_target_id
      self.channels.each do |channel_name, options|
        if options[:aggregate_grouping] && params[:group_id].blank?
          errors.add(:params, "requires group_id when aggregate_grouping is set to true")
        end
      end
    end

    def unsubscribed_validation
      errors.add(:target, (" has unsubscribed from this type")) if user_has_unsubscribed?
    end

    def user_has_unsubscribed?
      #return true if user has unsubscribed
      return true unless NotifyUser::Unsubscribe.has_unsubscribed_from(self.target, self.type).empty?

      return false
    end

    def self.unsubscribed_from_channel?(user, type)
      #return true if user has unsubscribed
      return !NotifyUser::Unsubscribe.has_unsubscribed_from(user, type).empty?
    end


  end
end
