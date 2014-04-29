class ApnsChannel

  class << self
  
  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(notification, options={})
      NotifyUser::Apns.push_notification(notification)
    end

  end

end