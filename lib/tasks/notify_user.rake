namespace :notify_user do

  desc "move params hash to json" 
  task :move_params_to_json => :environment do
    notifications = NotifyUser::BaseNotification.all

    notifications.each do |notification|
      notification.json = notification.params.to_json
      notification.save
    end

    puts "Moved params to json"

  end
end
