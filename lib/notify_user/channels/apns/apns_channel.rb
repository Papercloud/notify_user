class ApnsChannel

  class << self
  
  	def default_options
  	  {
  	    description: "Apple push notifications service"
  	  }
  	end

    def deliver(notification, options={})
      NotifyUser::Apns.push_notification(notification)
    end

  end

end