module NotifyUser
  class BaseNotification < ActiveRecord::Base

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :params, :target_id, :target_type, :type
    end

    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

    # Params for creating the notification message
    serialize :params, Hash

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target, :type

    def message
      "This is a base notification, params: #{params.to_json}"
    end

    # Send any Emails/SMS/APNS
    def deliver
      # TODO: Needs to be queued.
      NotificationMailer.notification_email(self).deliver
    end
  end
end
