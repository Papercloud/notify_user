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

    def deliver(notification_id, options={})
      if notification_id.is_a? NotifyUser::BaseNotification
        raise RuntimeError, "Must pass notification ids, not the notification itself"
      end

      notification = NotifyUser::BaseNotification.find(notification_id)

      NotifyUser::NotificationMailer.notification_email(notification, default_options.deep_merge(options)).deliver
    end

    def deliver_aggregated(notification_ids, options={})
      if notification_ids.first.is_a? NotifyUser::BaseNotification
        raise RuntimeError, "Must pass notification ids, not the notifications themselves"
      end

      notifications = NotifyUser::BaseNotification.where(id: notification_ids)

      NotifyUser::NotificationMailer.aggregate_notifications_email(notifications, default_options.deep_merge(options)).deliver
    end
  end
end