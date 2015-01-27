require_relative 'apn_connection'
require 'houston'

module NotifyUser
  class Houston < Apns

    APN_POOL = ConnectionPool.new(
      size: NotifyUser.connection_pool_size,
      timeout: NotifyUser.connection_pool_timeout) do
      APNConnection.new
    end

    NO_ERROR = -42

    def push
      space_allowance = PAYLOAD_LIMIT - used_space

      push_options = {
        alert: @notification.mobile_message(space_allowance),
        badge: @notification.count_for_target,
      }

      Houston.notify(push_options, @notification.target.devices)
    end

    class << self

      def notify(push_options = {}, devices)
        APN_POOL.with do |connection|
          connection = APNConnection.new

          ssl = connection.ssl
          error_index = NO_ERROR

          devices.each_with_index do |device, index|
            notification = ::Houston::Notification.new(push_options.dup.merge({ token: device.token, id: index }))

            connection.write(notification.message)
          end

          read_socket, write_socket = IO.select([ssl], [], [ssl], 1)
          if (read_socket && read_socket[0])
            if error = connection.connection.read(6)
              command, status, error_index = error.unpack("ccN")

              if error_index != NO_ERROR
                device = devices[error_index]

                if device.failures + 1 > NotifyUser.failure_tolerance
                  # Delete the device token if it has failed consecutively too many times:
                  device.delete
                else
                  # Up the failure rate for the device that failed to send:
                  device.update_attributes(failures: device.failures + 1)
                end
              end
            end
          end

          # Set the failure rate for all successfully sent notifications back to 0:
          Device.where(id: devices[0...error_index].map(&:id)).update_all(failures: 0 )

          # Resend all notifications after the once that produced the error:
          notify(push_options, devices[(error_index+1)..-1]) if error_index != NO_ERROR
        end
      end

    end

  end
end