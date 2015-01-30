module NotifyUser
  class NotificationMailer < ActionMailer::Base
    helper NotifyUser::ApplicationHelper

    layout "notify_user/layouts/action_mailer"
  
    def notification_email(notification, options)
      @notification = notification

      mail to: notification.target.email,
           subject: subject(notification, options[:subject]),
           template_name: "notification",
           template_path: "notify_user/action_mailer",
           from: NotifyUser.mailer_sender
    end

    def aggregate_notifications_email(notifications, options)
      @notifications = notifications
      @notification = notifications.first

      mail to: @notifications.first.target.email,
           template_name: "aggregate_notification",
           template_path: ["notify_user/#{notifications.first.class.name.underscore}/action_mailer", "notify_user/action_mailer"],
           subject: subject(@notification, options[:aggregate][:subject]),
           from: NotifyUser.mailer_sender
    end

    def subject(notification, subject)
      subject % notification.params.symbolize_keys
    end

    protected
  end
end