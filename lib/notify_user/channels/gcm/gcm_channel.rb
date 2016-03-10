class GcmChannel
  class << self

  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(notification, options={})
      devices = fetch_devices(notification, options[:device_method])

      NotifyUser::Gcm.new([notification], devices, options).push if devices.any?
    end

    def deliver_aggregated(notifications, options={})
      devices = fetch_devices(notifications.first, options[:device_method])

      NotifyUser::Gcm.new(notifications, devices, options).push if devices.any?
    end

    private

    def fetch_devices(notification, device_method = nil)
      device_method ||= :devices
      devices = notification.target.send(device_method)

      devices.android.to_a
    rescue
      [].tap do |devices|
        Rails.logger.info "Notification target, #{notification.target.class}, does not respond to the method, #{device_method}."
      end
    end
  end
end
