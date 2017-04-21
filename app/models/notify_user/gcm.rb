require 'gcm'

module NotifyUser
  class Gcm < Push
    PAYLOAD_LIMIT = 4096

    def push
      send_notifications
    end

    private

    def client
      @client ||= GCM.new(ENV['GCM_API_KEY'])
    end

    def valid?(payload)
      payload.to_json.bytesize <= PAYLOAD_LIMIT
    end

    def send_notifications
      device = fetch_device(delivery.notification, delivery.device_token)
      fail "Device not registered for target" unless device

      notification_data = build_notification(delivery.notification)
      response = client.send(device.token, notification_data)

      log_response_to_delivery(response)
      handle_response(response, device)
    end

    def fetch_device(notification, device_token)
      notification.target.devices.find_by(token: device_token)
    end

    def build_notification(notification)
      return Factories::Gcm.build(notification, options)
    end

    def log_response_to_delivery(response)
      body = JSON.parse(response[:body])
      delivery.update(status: response[:status_code], reason: body['results'][0]['error'])
    end

    def handle_response(response, device)
      body = JSON.parse(response[:body])

      if body['failure'] > 0 && (body['results'][0]['error'] == 'InvalidRegistration' || body['results'][0]['error'] == 'NotRegistered')
        device.destroy
      end
    end
  end
end
