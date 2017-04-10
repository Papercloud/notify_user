require_relative 'apn_connection'

module NotifyUser
  class Apns < Push

    def push
      APNConnection::POOL.with do |connection|
        send_notifications(connection)
      end
    end

    private

    def send_notifications(connection)
      device = fetch_device(delivery.notification, delivery.device_token)
      fail "Device not registered for target" unless device

      notification = build_notification(delivery.notification, device)
      response = connection.write(notification)

      fail "Timeout sending a push notification" unless response

      log_response_to_delivery(response)
      handle_response(response, device)
    end

    def fetch_device(notification, device_token)
      notification.target.devices.find_by(token: device_token)
    end

    def build_notification(notification, device)
      if options[:silent]
        return Factories::Apns.build_silent(notification, device.token, options)
      else
        return Factories::Apns.build(notification, device.token, options)
      end
    end

    def log_response_to_delivery(response)
      delivery.update(status: response.status, reason: response.body['reason'])
    end

    def handle_response(response, device)
      if response.status == '410' || (response.status == '400' && response.body['reason'] == 'BadDeviceToken')
        device.destroy
      end
    end
  end
end
