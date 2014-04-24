#removes the username and password fields from database.yml
system("cat #{ENV['RAILS_ROOT']}/config/database.yml | grep -v 'username' > #{ENV['RAILS_ROOT']}/config/database2.yml ")
system("cat #{ENV['RAILS_ROOT']}/config/database2.yml | grep -v 'password' > #{ENV['RAILS_ROOT']}/config/database.yml ")

rake "db:drop:all"
rake "db:create:all"

generate :model, 'user email:string'

generate "notify_user:install"
generate "notify_user:notification NewPostNotification"

gem_dir = File.expand_path('..',File.dirname(__FILE__))

# Finalise
rake "db:migrate"
rake "db:test:prepare"