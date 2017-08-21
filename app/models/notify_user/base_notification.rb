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
      attr_accessible :params, :target, :type, :state, :group_id, :parent_id
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
    validate :presence_of_group_id

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
        transitions from: [:pending, :sent, :pending_as_aggregation_parent, :sent_as_aggregation_parent], to: :read
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
      NotifyUser::BaseNotification.for_target(target)
        .where('parent_id IS NULL')
        .where('state IN (?)', ["sent_as_aggregation_parent", "sent", "pending"])
        .count
    end

    def self.aggregate_message(notifications)
      string = ActionView::Base.new(
             ActionController::Base.view_paths).render(
             :template => self.class.views[:mobile_sdk][:aggregate_path].call(self), :formats => [:html],
             :locals => { :notifications => notifications})

      return ::CGI.unescapeHTML("#{string}")
    end

    def message
      string = ActionView::Base.new(
             ActionController::Base.view_paths).render(
             :template => self.class.views[:mobile_sdk][:template_path].call(self), :formats => [:html],
             :locals => { :params => self.params, :notification => self})

      return ::CGI.unescapeHTML("#{string}")
    end

    def mobile_message(length=115)
      string = truncate(ActionView::Base.new(
             ActionController::Base.view_paths).render(
             :template => self.class.views[:mobile_sdk][:template_path].call(self), :formats => [:html],
             :locals => { :params => self.params, :notification => self}), :length => length)

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

    def grouped_by_id(group_id)
      self.group_id = group_id
      self
    end

    def notify!
      # Bang version of 'notify' ignores aggregation
      dont_aggregate!
    end

    # Send any Emails/SMS/APNS
    def notify(deliver=true)
      #All notifications except the notification at interval 0 should have there parent_id set
      if self.aggregate_grouping
        parents = current_parents.where(parent_id: nil).where('created_at >= ?', 24.hours.ago).order('created_at DESC')

        if parents.any?
          self.parent_id = parents.first.id
        end
      end

      # Sends with aggregation if enabled
      save

      ## if deliver == false don't perform deliver log but still perform aggregation logic
      ## notification then gets marked as sent
      mark_as_sent! unless deliver
    end

    def generate_unsubscribe_hash
      #check if a hash already exists for that user otherwise create a new one
      return NotifyUser::UserHash.where(target_id: self.target.id).where(target_type: self.target.class.base_class).where(type: self.type).where(active: true).first || NotifyUser::UserHash.create(target: self.target, type: self.type, active: true)
    end

    def aggregation_interval
      pending_and_sent_aggregation_parents.count
    end

    def delay_time(options)
      a_interval = options[:aggregate_per][aggregation_interval]

      # uses the last interval by default once we deplete the intervals
      a_interval = options[:aggregate_per].last if a_interval.nil?

      # last sent notification
      last_sent_parent = sent_aggregation_parents.first
      # Uses the time of the last notification sent otherwise will send it now.
      delay_time = last_sent_parent ? last_sent_parent.sent_time : created_at

      # If this is the first notification the aggregate interval will return 0. Thus sending the notification now!
      return delay_time + a_interval.minutes
    end

    ## Notification description
    class_attribute :description
    self.description = ""

    ## Channels
    class_attribute :channels
    self.channels = {
    }

    ## Aggregation

    class_attribute :aggregate_per
    self.aggregate_per = 1.minute

    ## True will implement a grouping/aggregation algorithm so that even though 10 notifications are delivered eg. Push Notifications
    ## Only 1 notification will be displayed to the user within the notification.json payload
    class_attribute :aggregate_grouping
    self.aggregate_grouping = false

    # Not sure about this. The JSON and web feeds don't fit into channels, because nothing is broadcast through
    # them. Not sure if they really need another concept though, they could just be formats on the controller.
    class_attribute :views
    self.views = {
      mobile_sdk: {
        template_path: Proc.new {|n| "notify_user/#{n.class.name.underscore}/mobile_sdk/notification" },
        aggregate_path: Proc.new {|n| "notify_user/#{n.class.name.underscore}/mobile_sdk/aggregate_notifications" }
      }
    }

    # Configure a channel
    def self.channel(name, options={})
      channels_clone = self.channels.clone
      channels_clone[name] = options
      self.channels = channels_clone
    end

    ## Sending

    def self.for_target(target)
      where(target_id: target.id)
      .where(target_type: target.class.base_class)
    end

    # Returns all parent notifications with a given group_id
    def current_parents
      self.class
      .for_target(self.target)
      .where(group_id: group_id)
    end

    def aggregation_parents
      current_parents
      .where('id != ?', id)
    end

    def sent_aggregation_parents
      aggregation_parents
      .where(state: :sent_as_aggregation_parent)
      .order('created_at DESC')
    end

    def pending_and_sent_aggregation_parents
      aggregation_parents
      .where(state: [:sent_as_aggregation_parent, :pending_as_aggregation_parent])
      .order('created_at DESC')
    end

    # Used for aggregation when grouping isn't enabled
    def self.pending_aggregations_marked_as_parent(notification)
      where(type: notification.type)
      .for_target(notification.target)
      .where(state: :pending_as_aggregation_parent)
    end

    # Used for aggregation when grouping based on group_id for target
    def self.pending_aggregations_grouped_marked_as_parent(notification)
      where(type: notification.type)
      .for_target(notification.target)
      .where(state: :pending_as_aggregation_parent)
      .where(group_id: notification.group_id)
    end

    # Used to find all pending notifications with aggregation enabled for target
    def self.pending_aggregation_by_group_with(notification)
      for_target(notification.target)
      .where(state: [:pending, :pending_as_aggregation_parent])
      .where(group_id: notification.group_id)
    end

    # Used to find all pending notifications for target
    def self.pending_aggregation_with(notification)
      where(type: notification.type)
      .for_target(notification.target)
      .where(state: [:pending, :pending_as_aggregation_parent])
    end

    def aggregation_pending?
      # A notification of the same type, that would have an aggregation job associated with it,
      # already exists.

      # When group aggregation is enabled we provide a different scope
      if self.aggregate_grouping
        return (self.class.pending_aggregations_grouped_marked_as_parent(self).where('id != ?', id).count > 0)
      else
        return (self.class.pending_aggregations_marked_as_parent(self).where('id != ?', id).count > 0)
      end
    end

    # Aggregates appropriately
    def deliver
      if pending? and not user_has_unsubscribed?
        # if aggregation is false bypass aggregation completely
        self.channels.each do |channel_name, options|
          if(options[:aggregate_per] == false)
            self.mark_as_sent!
            DeliverNotificationChannel.enqueue(self.class, self.id, channel_name, run_at: 5.seconds.from_now)
          else
            # only notifies channels if no pending aggregate notifications
            unless aggregation_pending?
              self.mark_as_pending_as_aggregation_parent!

              # adds fallback support for integer or array of integers
              if options[:aggregate_per].kind_of?(Array)
                NotifyAggregatedChannel.enqueue(self.class, self.id, channel_name, run_at: delay_time(options))
              else
                a_interval = options[:aggregate_per] ? options[:aggregate_per].minutes : self.aggregate_per
                NotifyAggregatedChannel.enqueue(self.class, self.id, channel_name, run_at: a_interval.minutes.from_now )
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

      unless notification.user_has_unsubscribed?(channel_name)
        channel.deliver(notification, channel_options)
      end
    end

    # Deliver a aggregated notifications to a specific channel.
    def self.deliver_notifications_channel(notifications, channel_name)
      channel_options = channels[channel_name.to_sym]
      channel = (channel_name.to_s + "_channel").camelize.constantize

      #check if user unsubsribed from channel type
      unless notifications.first.user_has_unsubscribed?(channel_name)
        channel.deliver_aggregated(notifications, channel_options)
      end
    end

    # Prepares a single channel for aggregation
    def self.notify_aggregated_channel(notification_id, channel_name)
      notification = self.find(notification_id) # Raise an exception if not found.

      # Find any pending notifications with the same type and target, which can all be sent in one message.
      if self.aggregate_grouping
        notifications = self.pending_aggregation_by_group_with(notification)
      else
        notifications = self.pending_aggregation_with(notification)
      end

      notifications.map(&:mark_as_sent)
      notifications.map(&:save)

      # If the notification has been marked as read before it's sent we don't want to send it.
      return if notification.read? || notifications.empty?

      if notifications.length == 1
        # Despite waiting for more to aggregate, we only got one in the end.
        self.deliver_notification_channel(notifications.first.id, channel_name)
      else
        # We got several notifications while waiting, send them aggregated.
        self.deliver_notifications_channel(notifications, channel_name)
      end
    end

    def user_has_unsubscribed?(channel_name=nil)
      #return true if user has unsubscribed
      return Unsubscribe.has_unsubscribed_from?(self.target, self.type, self.group_id, channel_name)
    end

    private

    def presence_of_group_id
      if self.aggregate_grouping && group_id.blank?
        errors.add(:group_id, "required when aggregate_grouping is set to true")
      end
    end

    def unsubscribed_validation
      errors.add(:target, (" has unsubscribed from this type")) if user_has_unsubscribed?
    end

    def self.unsubscribed_from_channel?(user, type)
      #return true if user has unsubscribed
      return !NotifyUser::Unsubscribe.has_unsubscribed_from(user, type).empty?
    end
  end
end
