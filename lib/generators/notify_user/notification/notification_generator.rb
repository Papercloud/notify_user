module NotifyUser
  class NotificationGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)
    class_option :skip, default: true

    def generate_notification
      template "notification.rb.erb", "app/notifications/#{name.underscore}.rb"
      puts "If you wish this notification to be unsubscribable add it to the unsubscribable_notifications array in the initializer"

    end

    def generate_view_scaffolds
      template "email_template.html.erb.erb", "app/views/notify_user/#{name.underscore}/action_mailer/notification.html.erb"
      template "email_layout_template.html.erb.erb", "app/views/notify_user/layouts/action_mailer.html.erb"
    end
  end
end