#removes the username and password fields from database.yml
remove_file "#{ENV['RAILS_ROOT']}/config/database.yml"
copy_file File.expand_path('../support/database.yml'), "#{ENV['RAILS_ROOT']}/config/database.yml"

rake "db:drop:all"
rake "db:create:all"

generate :model, 'user email:string'

generate "notify_user:install"
generate "notify_user:notification NewPostNotification"
generate "notify_user:notification TestNotification"

gem_dir = File.expand_path('..',File.dirname(__FILE__))

# Finalise
rake "db:migrate"
rake "db:test:prepare"