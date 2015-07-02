class ActionMailerChannel

  class << self

    def default_options
      {
        subject: "New Notification",
        aggregate: {
          subject: "New Notifications"
        },
        description: "Email Notifications"
      }
    end

    def deliver(notification, options={})
      NotifyUser::NotificationMailer.notification_email(notification, default_options.deep_merge(options)).deliver
    end

    def deliver_aggregated(notifications, options={})
      NotifyUser::NotificationMailer.aggregate_notifications_email(notifications, default_options.deep_merge(options)).deliver
    end

  end

end