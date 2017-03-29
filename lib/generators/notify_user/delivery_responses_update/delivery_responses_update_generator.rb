require 'rails/generators/active_record'

class NotifyUser::DeliveryResponsesUpdateGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_migrations
    copy_migration "add_responses_to_deliveries"

    puts "Installation successful. You can now run:"
    puts "  rake db:migrate"
  end
end
