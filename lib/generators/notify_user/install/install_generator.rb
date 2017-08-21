require 'rails/generators/active_record'

class NotifyUser::InstallGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_migrations
    copy_migration "create_notify_user_notifications"
    copy_migration "create_notify_user_unsubscribes"
    copy_migration "create_notify_user_user_hashes"
    copy_migration "add_que"

    puts "Installation successful. You can now run:"
    puts "  rake db:migrate"
  end

  def copy_initializer
    template "initializer.rb", "config/initializers/notify_user.rb"
  end

  def copy_notifications_controller
    template "notifications_controller.rb", "app/controllers/notify_user/notifications_controller.rb"
  end

  # This is defined in ActiveRecord::Generators::Base, but that inherits from NamedBase, so it expects a name argument
  # which we don't want here. So we redefine it here. Yuck.
  def self.next_migration_number(dirname)
    next_migration_number = current_migration_number(dirname) + 1
    ActiveRecord::Migration.next_migration_number(next_migration_number)
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
