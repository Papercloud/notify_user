class ApnsChannel

  class << self
  
    def deliver(notification, options={})
      NotifyUser::Apns.push_notification(notification)
    end

  end

end