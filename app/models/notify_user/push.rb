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

    private

    attr_accessor :device_tokens

    def device_tokens
      @device_tokens = @devices.map(&:token)
    end
  end
end
