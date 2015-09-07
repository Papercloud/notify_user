require 'gcm'

module NotifyUser
  class Gcm < Push
    PAYLOAD_LIMIT = 4096

    attr_accessor :client, :push_options

    def initialize(notifications, devices, options)
      super(notifications, devices, options)

      @push_options = setup_options
    end

    def push
      send_notifications
    end

    def client
      if Rails.env.development? || environment == :development
        @client ||= GCM.new(ENV['GCM_DEBUG_KEY'])
      else
        @client ||= GCM.new(ENV['GCM_RELEASE_KEY'])
      end
    end

    def environment
      return nil unless ENV['GCM_ENVIRONMENT']

      ENV['GCM_ENVIRONMENT'].downcase.to_sym
    end

    def valid?(payload)
      payload.to_json.bytesize <= PAYLOAD_LIMIT
    end

    private

    def setup_options
      space_allowance = PAYLOAD_LIMIT - used_space
      mobile_message = ''

      if @notification.parent_id
        parent = @notification.class.find(@notification.parent_id)
        mobile_message = parent.mobile_message(space_allowance)
      else
        mobile_message = @notification.mobile_message(space_allowance)
      end

      {
        data: {
          notification_id: @notification.id,
          message: mobile_message,
          type: @options[:category] || @notification.type,
          unread_count: @notification.count_for_target,
          custom_data: @notification.params,
        }
      }
    end

    def send_notifications
      @key = create_notification_key

      client.send(device_tokens, @push_options)
    end
  end
end
