class ApnsChannel

  class << self
  
    def deliver(notification, options={})
      puts "delivering push notification"
      NotifyUser::Apns.push_notification(notification)
    end

  end

end