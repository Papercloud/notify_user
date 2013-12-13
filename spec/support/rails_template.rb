generate :model, 'user email:string'

gem 'sidekiq'
bundle_command("install")
rake "sidekiq:install"

generate "notify_user:install"
generate "notify_user:notification NewPostNotification"

# Finalise
rake "db:migrate"
rake "db:test:prepare"