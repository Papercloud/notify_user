require_relative 'apn_connection'
require 'houston'

module NotifyUser
  class Houston < Apns

    APN_POOL = ConnectionPool.new(
      size: NotifyUser.connection_pool_size,
      timeout: NotifyUser.connection_pool_timeout) do
      APNConnection.new
    end

    def push
      space_allowance = PAYLOAD_LIMIT - used_space

      APN_POOL.with do |connection|
        devices = @notification.target.devices

        devices.each do |device|
          h_notification = ::Houston::Notification.new(device: device.token)

          h_notification.alert = @notification.mobile_message(space_allowance)
          h_notification.badge = @notification.count_for_target

          begin
            connection.write(h_notification.message)
          rescue Exception => e
            device.delete
            next
          end
        end
      end
    end

  end
end