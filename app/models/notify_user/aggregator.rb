module NotifyUser
  class Aggregator
    def initialize(notification, aggregation_intervals)
      @notification = notification
      @aggregation_intervals = aggregation_intervals
    end

    def has_pending_deliveries?
      if notification.class.aggregate_grouping?
        unread_unsent_notifications_for_group.any?
      else
        unread_unsent_notifications.any?
      end
    end

    def delay_time_in_seconds
      delay_time_in_minutes = aggregation_intervals[aggregation_interval] || aggregation_intervals.last
      delay_time_in_minutes * 60
    end

    def last_send_time
      notification.class.for_target(notification.target)
        .where(group_id: notification.group_id)
        .where.not(id: notification.id)
        .maximum(:created_at)
    end

    private

    attr_reader :notification, :aggregation_intervals

    def unread_unsent_notifications
      @unread_unsent_notifications ||= notification.class.for_target(notification.target)
        .joins(:deliveries)
        .where.not(id: notification.id)
        .where('notify_user_notifications.read_at IS NULL AND notify_user_deliveries.sent_at IS NULL')
    end

    def unread_unsent_notifications_for_group
      @unread_unsent_notifications_for_group ||= unread_unsent_notifications.where('notify_user_notifications.group_id = ?', notification.group_id)
    end

    # Finding the appropriate delay time:
    def last_read_notification
      @last_read_notification ||= notification.class.for_target(notification.target)
        .where.not(read_at: nil)
        .order(read_at: :desc)
        .first
    end

    def unread_notifications_since_last_read
      notification.class.for_target(notification.target)
        .where(group_id: notification.group_id)
        .where(read_at: nil)
        .where('notify_user_notifications.created_at >= ?', last_read_notification.try(:read_at) || 24.hours.ago)
        .where.not(id: notification.id)
        .order(created_at: :desc)
    end

    def aggregation_interval
      unread_notifications_since_last_read.count
    end
  end
end
