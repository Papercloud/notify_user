module NotifyUser
  class NotificationMailer < ActionMailer::Base
  
    def notification_email(notification, options)
      @notification = notification

      mail to: notification.target.email,
           subject: options[:subject],
           template_name: "notification",
           template_path: "notify_user/#{notification.class.name.underscore}/action_mailer",
           from: NotifyUser.mailer_sender
    end

    def aggregate_notifications_email(notifications, options)
      @notifications = notifications
      mail to: @notifications.first.target.email,
           template_name: "aggregate_notification",
           template_path: ["notify_user/#{notifications.first.class.name.underscore}/action_mailer", "notify_user/action_mailer"],
           subject: options[:aggregate][:subject],
           from: NotifyUser.mailer_sender
    end
  end
end