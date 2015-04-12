module NotifyUser
  class APNConnection

    attr_accessor :connection

    def initialize
      setup
    end

    def setup
      @uri, @certificate = if Rails.env.development? || apn_environment == :development
        Rails.logger.info "Using development gateway. Rails env: #{Rails.env}, APN_ENVIRONMENT: #{apn_environment}"
        [
          ::Houston::APPLE_DEVELOPMENT_GATEWAY_URI,
          File.read("#{Rails.root}/config/keys/development_push.pem")
        ]
      else
        Rails.logger.info "Using production gateway. Rails env: #{Rails.env}, APN_ENVIRONMENT: #{apn_environment}"
        [
          ::Houston::APPLE_PRODUCTION_GATEWAY_URI,
          File.read("#{Rails.root}/config/keys/production_push.pem")
        ]
      end

      @connection = ::Houston::Connection.new(@uri, @certificate, nil)
      @connection.open
    end

    def write(data)
      raise "Connection is closed" unless @connection.open?
      @connection.write(data)
    end

    private

    def apn_environment
      return nil unless ENV['APN_ENVIRONMENT']

      ENV['APN_ENVIRONMENT'].downcase.to_sym
    end

  end
end