require_relative 'apn_connection'
require 'houston'

module NotifyUser
  class Houston < Apns

    NO_ERROR = -42
    APN_POOL = ConnectionPool.new(
      size: NotifyUser.connection_pool_size,
      timeout: NotifyUser.connection_pool_timeout) do
      APNConnection.new
    end

    def initialize(notification, options)
      super(notification, options)

      @devices = @notification.target.devices.order(:id).reverse
    end

    def push
      space_allowance = PAYLOAD_LIMIT - used_space

      @push_options = {
        alert: @notification.mobile_message(space_allowance),
        badge: @notification.count_for_target,
        category: @notification.params[:category] || @notification.type,
        custom_data: @notification.params
      }

      send_notifications
    end

    def send_notifications
      APN_POOL.with do |connection|
        if !connection.connection.open?
          connection = APNConnection.new
        end

        ssl = connection.ssl
        error_index = NO_ERROR

        @devices.each_with_index do |device, index|
          notification = ::Houston::Notification.new(@push_options.dup.merge({ token: device.token, id: index }))

          connection.write(notification.message)
        end

        read_socket, write_socket = IO.select([ssl], [], [ssl], 1)
        if (read_socket && read_socket[0])
          if error = connection.connection.read(6)
            command, status, error_index = error.unpack("ccN")

            if error_index != NO_ERROR
              device = @devices[error_index]
              range = 0...error_index

              if device.failures + 1 >= NotifyUser.failure_tolerance
                # Delete the device token if it has failed consecutively too many times:
                device.delete
                range = 0..error_index
              else
                # Up the failure rate for the device that failed to send:
                device.update_attributes(failures: device.failures + 1)
              end

              # Close the connection:
              connection.connection.close

              # Set the failure rate for all successfully sent notifications back to 0:
              Device.where(id: @devices.slice!(range).map(&:id)).update_all(failures: 0 )
            end
          end
        end

        # Resend all notifications after the once that produced the error:
        send_notifications if error_index != NO_ERROR
      end
    end
  end
end