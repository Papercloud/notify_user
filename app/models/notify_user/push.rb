module NotifyUser
  class Push

    attr_reader :delivery, :options

    def initialize(delivery, options)
      @delivery = delivery
      @options = options
    end

    # Sends push notification:
    def push
      raise "Base Push class should not be used."
    end

  end
end
