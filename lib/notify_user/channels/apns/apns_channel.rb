class ApnsChannel
  class << self

  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(notification, options={})
      @devices = fetch_devices(notification, options[:device_method])

      NotifyUser::Apns.new([notification], @devices[:ios], options).push if @devices[:ios].any?
      NotifyUser::Gcm.new([notification], @devices[:android], options).push if @devices[:android].any?
    end

    def deliver_aggregated(notifications, options={})
      @devices = fetch_devices(notifications.first, options[:device_method])

      NotifyUser::Apns.new(notifications, @devices[:ios], options).push if @devices[:ios].any?
      NotifyUser::Gcm.new(notifications, @devices[:android], options).push if @devices[:android].any?
    end

    private

    def fetch_devices(notification, device_method = nil)
      device_method ||= :devices
      devices = notification.target.send(device_method)

      { ios: devices.ios.to_a, android: devices.android.to_a }
    rescue
      Rails.logger.info "Notification target, #{notification.target.class}, does not respond to the method, #{device_method}."
      { ios: [], android: [] }
    end
  end
end
