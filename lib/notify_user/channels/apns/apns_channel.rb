class ApnsChannel
  class << self

  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(delivery_id, options={})
      if delivery_id.is_a? NotifyUser::BaseNotification
        raise RuntimeError, "Must pass delivery id, not the delivery itself"
      end

      delivery = NotifyUser::Delivery.find(delivery_id)
      NotifyUser::Apns.new(delivery, options).push
    end
  end
end
