generate :model, 'user email:string'

generate "notify_user:install"
generate "notify_user:notification NewPostNotification"

# Finalise
rake "db:migrate"
rake "db:test:prepare"