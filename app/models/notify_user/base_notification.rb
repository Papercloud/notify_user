require 'state_machine'
require 'sidekiq'

module NotifyUser
  class BaseNotification < ActiveRecord::Base
    include ActionView::Helpers::TextHelper

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :params, :target, :type, :state
    end

    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

    #checks if user has unsubscribed from this notif type
    validate :unsubscribed_validation

    # Params for creating the notification message.
    # serialize :params, Hash

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type, :state

    state_machine :state, initial: :pending do

      # Created, not sent yet. Possibly waiting for aggregation.
      state :pending do
      end

      # Email/SMS/APNS has been sent.
      state :sent do
      end

      # The user has seen this notification.
      state :read do
      end

      # Record that we have sent message(s) to the user about this notification.
      event :mark_as_sent do
        transition :pending => :sent
      end

      # Record that the user has seen this notification, usually on a page or in the app.
      # A notification can go straight from pending to read if it's seen in a view before
      # sent in an email.
      event :mark_as_read do
        transition [:pending, :sent] => :read
      end
    end

    def params
      super.with_indifferent_access
    end

    def message
      ActionView::Base.new(
             Rails.configuration.paths["app/views"]).render(
             :template => self.class.views[:mobile_sdk][:template_path].call(self), :formats => [:html], 
             :locals => { :params => self.params}, :layout => false)
    end

    def mobile_message(length=115)
      truncate(ActionView::Base.new(
             Rails.configuration.paths["app/views"]).render(
             :template => self.class.views[:mobile_sdk][:template_path].call(self), :formats => [:html], 
             :locals => { :params => self.params}, :layout => false), :length => length)
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
      save

      # Bang version of 'notify' ignores aggregation
      self.deliver!
    end

    # Send any Emails/SMS/APNS
    def notify

      save

      #if aggregation is false bypass aggregation completely
      self.channels.each do |channel_name, options|
        if(options[:aggregate_per] == false)
          self.class.delay.deliver_notification_channel(self.id, channel_name)    
        else
          if not aggregation_pending?
            self.class.delay_for(options[:aggregate_per] || self.aggregate_per).notify_aggregated_channel(self.id, channel_name)
          end
        end
      end

    end

    def generate_unsubscribe_hash
      #check if a hash already exists for that user otherwise create a new one
      return NotifyUser::UserHash.where(target_id: self.target.id).where(target_type: self.target.class.base_class).where(type: self.type).where(active: true).first || NotifyUser::UserHash.create(target: self.target, type: self.type, active: true)
    end

    ## Notification description
    class_attribute :description
    self.description = ""

    ## Channels

    mattr_accessor :channels
    @@channels = {
      action_mailer: {description: 'Email notifications'}
    }

    # Not sure about this. The JSON and web feeds don't fit into channels, because nothing is broadcast through
    # them. Not sure if they really need another concept though, they could just be formats on the controller.
    mattr_accessor :views
    @@views = {
      mobile_sdk: {
        template_path: Proc.new {|n| "notify_user/#{n.class.name.underscore}/mobile_sdk/notification" }
      }
    }

    # Configure a channel
    def self.channel(name, options={})
      channels[name] = options
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
      .where(state: :pending)
    end

    def aggregation_pending?
      # A notification of the same type, that would have an aggregation job associated with it,
      # already exists.
      return (self.class.pending_aggregation_with(self).where('id != ?', id).count > 0)
    end

    # def deliver
    #   unless user_has_unsubscribed?
    #     self.mark_as_sent
    #     self.save

    #     self.class.delay.deliver_channels(self.id)
    #   end
    # end

    def deliver!
      unless user_has_unsubscribed?
        self.mark_as_sent
        self.save
        self.class.deliver_channels(self.id)
      end
    end

    # Deliver a single notification across each channel.
    def self.deliver_channels(notification_id)
      notification = self.where(id: notification_id).first
      return unless notification
      self.channels.each do |channel_name, options|
        unless unsubscribed_from_channel?(notification.target, channel_name)
          channel = (channel_name.to_s + "_channel").camelize.constantize
          channel.deliver(notification, options)
        end
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
      notification = self.where(id: notification_id).first
      return unless notification
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

    #notifies a single channel for aggregation
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

    def self.notify_aggregated(notification_id)
      notification = self.find(notification_id) # Raise an exception if not found.

      # Find any pending notifications with the same type and target, which can all be sent in one message.
      notifications = self.pending_aggregation_with(notification)
      
      notifications.map(&:mark_as_sent)
      notifications.map(&:save)

      return if notifications.empty?

      if notifications.length == 1
        # Despite waiting for more to aggregate, we only got one in the end.
        self.deliver_channels(notifications.first.id)
      else
        # We got several notifications while waiting, send them aggregated.
        self.deliver_channels_aggregated(notifications)
      end
    end

    private
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
      return true unless NotifyUser::Unsubscribe.has_unsubscribed_from(user, type).empty?  

      return false 
    end


  end
end
