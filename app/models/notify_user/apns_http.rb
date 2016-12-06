require_relative 'apn_http_connection'

module NotifyUser
  class ApnsHttp < Push
    attr_accessor :push_options

    def initialize(notifications, devices, options)
      super(notifications, devices, options)

      @devices = devices
    end

    def push
      APNHttpConnection::POOL.with do |connection|
        send_notifications(connection)
      end
    end

    private

    attr_accessor :devices

    def build_notification(device)
      if @options[:silent]
        return Factories::ApnsHttp.build_silent(@notification, device, @options)
      else
        return Factories::ApnsHttp.build(@notification, device, @options)
      end
    end

    def send_notifications(connection)
      devices.each_with_index do |device, index|
        notification = build_notification(device)
        response = connection.write(notification)

        raise "Timeout sending a push notification" unless response

        if response.status == '410' ||
            (response.status == '400' && response.body['reason'] == 'BadDeviceToken')
          Rails.logger.info "Invalid token encountered, removing device. Token: #{device.token}."
          device.destroy
        end
      end
    end
  end
end
