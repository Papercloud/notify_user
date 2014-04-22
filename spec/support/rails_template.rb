generate :model, 'user email:string'

generate "notify_user:install"
generate "notify_user:notification NewPostNotification"

gem_dir = File.expand_path('..',File.dirname(__FILE__))

system("cp #{gem_dir}/support/database.yml #{ENV['RAILS_ROOT']}/config/database.yml")

# Finalise
rake "db:migrate"
rake "db:test:prepare"