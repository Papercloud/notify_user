class PubnubChannel

  class << self

    def default_options
      {
        description: "PubNub Notifications"
      }
    end

    def deliver(notification, options={})
      NotifyUser::PubNub.push_notification(notification)
    end

  end

end