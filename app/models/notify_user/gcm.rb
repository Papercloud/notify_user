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
      @client ||= GCM.new(ENV['GCM_API_KEY'])
    end

    def valid?(payload)
      payload.to_json.bytesize <= PAYLOAD_LIMIT
    end

    private

    def mobile_message(notification, length)
      ChannelPresenter.present(notification, length)
    end

    def count_for_target(target)
      BaseNotification.unread_count_for_target(target)
    end

    def setup_options
      space_allowance = PAYLOAD_LIMIT - used_space
      mobile_message = ''

      if @notification.parent_id
        parent = @notification.class.find(@notification.parent_id)
        mobile_message = mobile_message(parent, space_allowance)
      else
        mobile_message = mobile_message(@notification, space_allowance)
      end

      {
        data: {
          notification_id: @notification.id,
          message: mobile_message,
          type: @options[:category] || @notification.type,
          unread_count: count_for_target(@notification.target),
          custom_data: @notification.sendable_params,
        }
      }
    end

    def send_notifications
      return unless device_tokens.any?
      response = client.send(device_tokens, @push_options)
      # should be checking for errors in the response here
      return true
    end
  end
end
