require 'state_machine'

module NotifyUser
  class BaseNotification < ActiveRecord::Base

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :params, :target_id, :target_type, :type, :state
    end

    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

    # Params for creating the notification message.
    serialize :params, Hash

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target, :type, :state

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

    ## For overriding by subclasses

    # TODO: Something not right here. Need an object to represent aggregate notifications.
    # Because you may want the subject to include content from each aggregated notification.

    def subject
      "You have a new notification"
    end

    def self.aggregate_per
      # TODO: Make this a user setting.
      # Consider delaying until a given time of day, rather than for a period. So we can do a daily digest at Xpm.
      1.minute
    end


    ## Scopes

    def self.pending_aggregation_with(notification)
      where(type: notification.type).where(target: notification.target).where(state: :pending)
    end

    ## Message sending and aggregation

    # TODO: Extend this to use views, i18n and to provide different views for diff formats
    # like JSON, HTML, SMS and APNS.
    def self.message(notification)
      "This is a base notification, params: #{notification.params.to_json}"
    end

    def deliver
      self.mark_as_sent
      self.save
      NotificationMailer.delay.notification_email(self.id).deliver
    end

    def self.deliver_aggregated(notifications)
      # Send a special aggregated message to the target
      # TODO: Needs to be more customisable.
      notifications.map(&:mark_as_sent)
      notifications.map(&:save)
      NotificationMailer.delay.aggregate_notifications_email(notifications.map(&:id)).deliver
    end

    # Send any Emails/SMS/APNS
    def notify

      if self.class.aggregate_per

        # Schedule to send later if there aren't already any scheduled.
        # Otherwise ignore, as the already-scheduled aggregate job will pick this one up when it runs.
        if self.class.pending_aggregation_with(self).count == 0

          # Send in X minutes, along with any others created in the intervening times.
          self.class.delay_for(self.class.aggregate_per).notify_aggregated(self.id)
        end
      else
        # No aggregation, send immediately.
        self.deliver
      end
    end

    def self.notify_aggregated(notification_id)
      notification = self.find_by_id(notification_id)
      return if not notification

      # Find any pending notifications with the same type and target, which can all be sent in one message.
      notifications = self.pending_aggregation_with(notification)
      
      self.deliver_aggregated(notifications)
    end

  end
end
