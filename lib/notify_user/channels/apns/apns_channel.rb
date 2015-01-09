class ApnsChannel

  class << self

  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(notification, options={})
      case NotifyUser.apns_provider
      when :houston
        NotifyUser::Houston.new(notification).push
      when :urban_airship
        # Check for the existence of development api keys and resend for development:
        if !ENV['DEV_UA_APPLICATION_KEY'].nil? && !ENV['DEV_UA_APPLICATION_SECRET'].nil? && !ENV['DEV_UA_MASTER_SECRET'].nil?

          Urbanairship.application_key = ENV['DEV_UA_APPLICATION_KEY']
          Urbanairship.application_secret = ENV['DEV_UA_APPLICATION_SECRET']
          Urbanairship.master_secret = ENV['DEV_UA_MASTER_SECRET']

          NotifyUser::UrbanAirship.new(notification).push

          # Sets the api keys back to their original state:

          Urbanairship.application_key = ENV['UA_APPLICATION_KEY']
          Urbanairship.application_secret = ENV['UA_APPLICATION_SECRET']
          Urbanairship.master_secret = ENV['UA_MASTER_SECRET']
        end
      end
    end

  end

end