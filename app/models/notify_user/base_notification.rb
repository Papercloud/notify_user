require 'state_machine'
require 'sidekiq'

module NotifyUser
  class BaseNotification < ActiveRecord::Base

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :params, :target, :type, :state
    end

    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

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

    ## For overriding by subclasses

    # TODO: Something not right here. Need an object to represent aggregate notifications.
    # Because you may want the subject to include content from each aggregated notification.
    # Could resolve this by making the aggregated templates available to the one being rendered,
    # as 'siblings' perhaps.

    def subject
      "You have a new notification"
    end

    def aggregate_subject
      "You have some new notifications"
    end

    def self.aggregate_per
      # TODO: Make this a user setting.
      # Consider delaying until a given time of day, rather than for a period. So we can do a daily digest at Xpm.
      1.minute
    end

    # TODO: Extend this to use views, i18n and to provide different views for diff formats
    # like JSON, HTML, SMS and APNS.
    def message
      "This is a base notification, params: #{params.to_json}"
    end

    ## Sending

    # Send any Emails/SMS/APNS
    def notify

      save!

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

    def self.pending_aggregation_with(notification)
      where(type: notification.type)
      .where(target_id: notification.target.id)
      .where(target_type: notification.target.class.name)
      .where(state: :pending)
    end

    def aggregation_pending?
      # A notification of the same type, that would have an aggregation job associated with it,
      # already exists.
      return (self.class.pending_aggregation_with(self).where('id != ?', id).count > 0)
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
      NotificationMailer.delay.aggregate_notifications_email(notifications.map(&:id))
    end

    def self.notify_aggregated(notification_id)
      notification = self.find(notification_id) # Raise an exception if not found.

      # Find any pending notifications with the same type and target, which can all be sent in one message.
      notifications = self.pending_aggregation_with(notification)
      
      self.deliver_aggregated(notifications)
    end

  end
end
