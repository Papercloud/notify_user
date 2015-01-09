require 'houston'

module NotifyUser
  class Houston < Apns

    APN_POOL = ConnectionPool.new(size: 2, timeout: 300) do
      APNConnection.new
    end

    def push
      space_allowance = PAYLOAD_LIMIT - used_space

      APN_POOL.with do |connection|
        tokens = @notification.target.devices.collect(&:token)

        tokens.each do |token|
          h_notification = ::Houston::Notification.new(device: token)

          h_notification.alert = @notification.mobile_message(space_allowance)
          h_notification.badge = @notification.count_for_target

          connection.write(h_notification.message)
        end
      end
    end

  end
end