require 'rails/generators/active_record'

class NotifyUser::InstallGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_migrations
    copy_migration "create_notify_user_notifications"
    copy_migration "create_notify_user_unsubscribes"
    copy_migration "create_notify_user_user_hashes"

    puts "Installation successful. You can now run:"
    puts "  rake db:migrate"
  end

  def copy_initializer
    template "initializer.rb", "config/initializers/notify_user.rb"
  end

  def copy_notifications_controller
    template "notifications_controller.rb", "app/controllers/notify_user/notifications_controller.rb"
  end

  def append_stylesheet
    insert_into_file "app/assets/stylesheets/application.css", :before => "*/" do
      "\n *= require 'notify_user_stylesheet'\n\n"
    end
  end

  # This is defined in ActiveRecord::Generators::Base, but that inherits from NamedBase, so it expects a name argument
  # which we don't want here. So we redefine it here. Yuck.
  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S%L")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  protected

    def copy_migration(filename)
      if self.class.migration_exists?("db/migrate", "#{filename}")
        say_status("skipped", "Migration #{filename}.rb already exists")
      else
        migration_template "#{filename}.rb", "db/migrate/#{filename}.rb"
      end
    end

end
