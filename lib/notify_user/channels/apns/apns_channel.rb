class ApnsChannel
  class << self

  	def default_options
  	  {
  	    description: "Push Notifications"
  	  }
  	end

    def deliver(notification_id, options={})
      if notification_id.is_a? NotifyUser::BaseNotification
        raise RuntimeError, "Must pass notification ids, not the notification itself"
      end

      notification = NotifyUser::BaseNotification.find(notification_id)

      devices = fetch_devices(notification, options[:device_method])

      NotifyUser::Apns.new([notification], devices, options).push if devices.any?
    end

    def deliver_aggregated(notification_ids, options={})
      if notification_ids.first.is_a? NotifyUser::BaseNotification
        raise RuntimeError, "Must pass notification ids, not the notifications themselves"
      end

      notifications = NotifyUser::BaseNotification.where(id: notification_ids)

      devices = fetch_devices(notifications.first, options[:device_method])

      NotifyUser::Apns.new(notifications, devices, options).push if devices.any?
    end

    private

    def fetch_devices(notification, device_method = nil)
      device_method ||= :devices
      devices = notification.target.send(device_method)

      devices.ios.to_a
    rescue
      [].tap do
        Rails.logger.info "Notification target, #{notification.target.class}, does not respond to the method, #{device_method}."
      end
    end
  end
end
