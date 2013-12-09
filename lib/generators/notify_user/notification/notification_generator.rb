module NotifyUser
  class NotificationGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def generate_notification
      template "notification.rb", "app/notifications/#{name.underscore}.rb"
    end
  end
end