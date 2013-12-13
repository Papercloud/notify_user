module NotifyUser
  class NotificationMailer < ActionMailer::Base
    default from: NotifyUser.mailer_sender
  
    # Subject can be set in your I18n file at config/locales/en.yml
    # with the following lookup:
    #
    #   en.notification_mailer.notification_email.subject
    #
    def notification_email(notification_id)

      notification = NotifyUser::BaseNotification.find(notification_id)

      @message = notification.message

      mail to: notification.target.email, subject: notification.subject
    end

    def aggregate_notifications_email(notification_ids)
      # TODO: Customise subject?
      # TODO: This is one where it would be great to customise the template.
      @notifications = NotifyUser::BaseNotification.where('id IN (?)', notification_ids)
      mail to: @notifications.first.target.email
    end
  end
end
