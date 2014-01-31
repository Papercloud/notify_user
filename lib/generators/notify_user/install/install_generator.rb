require 'rails/generators/active_record'

class NotifyUser::InstallGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_migration
    migration_template "migration.rb", "db/migrate/create_notify_user_notifications"
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
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

end
