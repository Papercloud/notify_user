module NotifyUser
  class Apns
    SYMBOL_NAMES_SIZE = 10
    PAYLOAD_LIMIT = 255

    def initialize(notification, options)
      @notification = notification
      @options = options
    end

    # Calculates the bytes already used:
    def used_space
      used_space = SYMBOL_NAMES_SIZE + @notification.id.size + @notification.created_at.to_time.to_i.size +
                    @notification.type.size

      used_space += @notification.params[:action_id].size if @notification.params[:action_id]

      used_space
    end

    # Sends push notification:
    def push
      raise "Base APNS class should not be used."
    end
  end
end
