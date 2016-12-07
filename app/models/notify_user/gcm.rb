require 'gcm'

module NotifyUser
  class Gcm < Push
    PAYLOAD_LIMIT = 4096

    attr_accessor :client, :push_options

    def initialize(notifications, devices, options)
      super(notifications, devices, options)
    end

    def push
      send_notifications
    end

    def client
      @client ||= GCM.new(ENV['GCM_API_KEY'])
    end

    def valid?(payload)
      payload.to_json.bytesize <= PAYLOAD_LIMIT
    end

    private

    def build_notification
      return Factories::Gcm.build(@notification, @options)
    end

    def send_notifications
      return unless device_tokens.any?
      notification_data = build_notification()

      response = client.send(device_tokens, notification_data)
      # should be checking for errors in the response here
      return true
    end
  end
end
