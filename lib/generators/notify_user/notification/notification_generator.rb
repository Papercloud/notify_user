module NotifyUser
  class NotificationGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def generate_notification
      template "notification.rb.erb", "app/notifications/#{name.underscore}.rb"
    end

    def generate_view_scaffolds
      template "email_template.html.erb.erb", "app/views/notify_user/#{name.underscore}/action_mailer/notification.html.erb"
      template "mobile_sdk_template.html.erb", "app/views/notify_user/#{name.underscore}/mobile_sdk/notification.html.erb"
    end
  end
end