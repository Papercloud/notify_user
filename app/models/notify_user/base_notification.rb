require 'state_machine'
require 'sidekiq'

module NotifyUser
  class BaseNotification < ActiveRecord::Base

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :params, :target, :type, :state
    end

    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

    #checks if user has unsubscribed from this notif type
    validate :unsubscribed_validation

    # Params for creating the notification message.
    serialize :params, Hash

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

      if self.class.aggregate_per

        # Schedule to send later if there aren't already any scheduled.
        # Otherwise ignore, as the already-scheduled aggregate job will pick this one up when it runs.
        if not aggregation_pending?

          # Send in X minutes, along with any others created in the intervening times.
          self.class.delay_for(self.class.aggregate_per).notify_aggregated(self.id)
        end
      else
        # No aggregation, send immediately.
        self.deliver
      end

    end

    ## Channels

    mattr_accessor :channels
    @@channels = {
      action_mailer: {},
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

    mattr_accessor :aggregate_per
    @@aggregate_per = 1.minute

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

    def deliver
      unless user_has_unsubscribed?
        self.mark_as_sent
        self.save

        self.class.delay.deliver_channels(self.id)
      end
    end

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
        channel = (channel_name.to_s + "_channel").camelize.constantize
        channel.deliver(notification, options)
      end
    end

    # Deliver multiple notifications across each channel as an aggregate message.
    def self.deliver_channels_aggregated(notifications)
      self.channels.each do |channel_name, options|
        channel = (channel_name.to_s + "_channel").camelize.constantize
        channel.deliver_aggregated(notifications, options)
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


  end
end
