require_relative 'apn_connection'
require 'houston'

module NotifyUser
  class Houston < Apns

    NO_ERROR = -42
    INVALID_TOKEN_ERROR = 8
    APN_POOL = ConnectionPool.new(
      size: NotifyUser.connection_pool_size,
      timeout: NotifyUser.connection_pool_timeout) do
      APNConnection.new
    end

    attr_accessor :push_options

    def initialize(notification, options)
      super(notification, options)

      @push_options = setup_options

      device_method = @options[:device_method] || :devices
      begin
        @devices = @notification.target.send(device_method)
      rescue
        Rails.logger.info "Notification target, #{@notification.target.class}, does not respond to the method, #{device_method}."
      end
    end

    def push
      send_notifications
    end

    private

    def setup_options
      space_allowance = PAYLOAD_LIMIT - used_space

      mobile_message = @notification.mobile_message(space_allowance)
      mobile_message.gsub!('\n', "\n")

      push_options = {
        alert: mobile_message,
        badge: @notification.count_for_target,
        category: @notification.params[:category] || @notification.type,
        custom_data: @notification.params,
        sound: 'default'
      }

      if @options[:silent]
        push_options.merge!({
          sound: '',
          content_available: true
        })
      end

      push_options
    end

    def send_notifications
      APN_POOL.with do |connection|
        if !connection.connection.open?
          connection = APNConnection.new
        end

        ssl = connection.connection.ssl
        error_index = NO_ERROR

        @devices.each_with_index do |device, index|
          notification = ::Houston::Notification.new(@push_options.dup.merge({ token: device.token, id: index }))
          connection.write(notification.message)
        end

        read_socket, write_socket = IO.select([ssl], [], [ssl], 1)
        if (read_socket && read_socket[0])
          if error = connection.connection.read(6)
            command, status, error_index = error.unpack("ccN")

            # Remove all the devices prior to the error (we assume they were successful), and close the current connection:
            if error_index != NO_ERROR
              device = @devices.at(error_index)
              Rails.logger.info "Error: #{status} with id: #{error_index}. Token: #{device.token}."

              # If we encounter the Invalid Token error from APNS, just remove the device:
              if status == ERROR_INVALID_TOKEN
                Rails.logger.info "Invalid token encountered, removing device. Token: #{device.token}."
                device.destroy
              end

              @devices.slice!(0..error_index)
              connection.connection.close
            end
          end
        end

        # Resend all notifications after the once that produced the error:
        send_notifications if error_index != NO_ERROR
      end
    end
  end
end