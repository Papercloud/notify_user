module NotifyUser
  class Push
    def initialize(notifications, devices, options)
      @notifications = notifications
      @notification = notifications.first

      @devices = devices
      @options = options
    end

    # Sends push notification:
    def push
      raise "Base Push class should not be used."
    end

    def delivery_for_notification(channel)
      Delivery.find_by(notification: @notification, channel: channel)
    end

    def log_response_to_delivery(device, response)
      return unless delivery.present?
      delivery.log_response_for_device(device, response)
    end

    def formatted_response
      raise "Formatted Response not defined"
    end

    private

    attr_accessor :device_tokens

    def device_tokens
      @device_tokens = @devices.map(&:token)
    end
  end
end
