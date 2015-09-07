class ApnsChannel

  class << self

  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(notification, options={})
      @devices = fetch_devices(notification)

      NotifyUser::Apns.new([notification], @devices[:ios], options).push if @devices[:ios].any?
      NotifyUser::Gcm.new([notification], @devices[:android], options).push if @devices[:android].any?
    end

    def deliver_aggregated(notifications, options={})
      @devices = fetch_devices(notification)

      NotifyUser::Apns.new(notifications, @devices[:ios], options).push if @devices[:ios].any?
      NotifyUser::Gcm.new(notifications, @devices[:android], options).push if @devices[:android].any?
    end

    private

    def fetch_devices(notification)
      device_method = options[:device_method] || :devices
      devices = notification.target.send(device_method)

      { ios: devices.ios, android: devices.android }
    rescue
      Rails.logger.info "Notification target, #{notification.target.class}, does not respond to the method, #{device_method}."
    end
  end
end