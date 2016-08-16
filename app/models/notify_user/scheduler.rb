module NotifyUser
  class Scheduler
    def self.schedule(notification)
      new(notification).schedule
    end

    def initialize(notification)
      @notification = notification
    end

    def schedule
      notification.class.channels.each do |channel, options|
        aggregator = Aggregator.new(notification, options[:aggregate_per])
        return if aggregator.has_pending_deliveries?

        # Create the delivery:
        delivery = Delivery.create!({
          notification: notification,
          deliver_in: delay_time(aggregator),
          channel: channel.to_s
        })
      end
    end

    private

    attr_reader :notification

    # Find the seconds to delay delivery by:
    def delay_time(aggregator)
      last_send_time = aggregator.last_send_time
      delay_time = aggregator.delay_time_in_seconds

      validate_delay_time(last_send_time, delay_time)
    end

    # Calculate the estimated send time:
    def validate_delay_time(last_send_time, delay_time)
      send_epoch = last_send_time.to_i + delay_time
      send_time_from_now = send_epoch - Time.zone.now.to_i

      # If the estimated send time is in the past, just send it now:
      send_time_from_now > 0 ? delay_time : 0
    end
  end
end
