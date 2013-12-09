module NotifyUser
  class NotificationMailer < ActionMailer::Base
    default from: "from@example.com"
  
    # Subject can be set in your I18n file at config/locales/en.yml
    # with the following lookup:
    #
    #   en.notification_mailer.notification_email.subject
    #
    def notification_email(notification)
      @message = notification.message

      mail to: notification.target.email
            # template_path: "notifications",
            # template_name: "notification"
    end
  end
end
