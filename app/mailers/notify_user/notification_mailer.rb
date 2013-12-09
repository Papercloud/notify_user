module NotifyUser
  class NotificationMailer < ActionMailer::Base
    default from: "from@example.com"
  
    # Subject can be set in your I18n file at config/locales/en.yml
    # with the following lookup:
    #
    #   en.notification_mailer.notification_email.subject
    #
    def notification_email(notification_id)

      notification = NotifyUser::BaseNotificaton.find(notification)

      @message = notification.message

      mail to: notification.target.email
            # template_path: "notifications",
            # template_name: "notification"
    end

    def aggregate_notifications_email(notification_ids)
      # TODO: Customise subject?
      # TODO: This is one where it would be great to customise the template.
      @notifications = NotifyUser::BaseNotificaton.where('id IN (?)', notification_ids)
      mail to: notifications.first.target.email
    end
  end
end
