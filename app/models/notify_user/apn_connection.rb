module NotifyUser
  class APNConnection

    POOL = ConnectionPool.new(
      size: (ENV['APNS_CONNECTION_POOL_SIZE'] ? ENV['APNS_CONNECTION_POOL_SIZE'].to_i : 1),
      timeout: (ENV['APNS_CONNECTION_TIMEOUT'] ? ENV['APNS_CONNECTION_TIMEOUT'].to_i : 30)) {
      APNConnection.new
    }

    def initialize
      connection
    end

    def connection
      @connection ||= setup_connection
    end

    def write(data)
      raise "Connection is closed" unless @connection.open?
      @connection.write(data)
    end

    def reset
      @connection.close if @connection
      @connection = nil
      connection
    end

    private

    def apn_environment
      return nil unless ENV['APN_ENVIRONMENT']

      ENV['APN_ENVIRONMENT'].downcase.to_sym
    end

    def setup_connection
      return if Rails.env.test?

      @uri, @certificate = if Rails.env.development? || apn_environment == :development
        Rails.logger.info "Using development gateway. Rails env: #{Rails.env}, APN_ENVIRONMENT: #{apn_environment}"
        [
          ::Houston::APPLE_DEVELOPMENT_GATEWAY_URI,
          File.read(development_certificate)
        ]
      else
        Rails.logger.info "Using production gateway. Rails env: #{Rails.env}, APN_ENVIRONMENT: #{apn_environment}"
        [
          ::Houston::APPLE_PRODUCTION_GATEWAY_URI,
          File.read(production_certificate)
        ]
      end

      @connection = ::Houston::Connection.new(@uri, @certificate, nil)
    end

    def development_certificate
      file_path = ENV['APN_DEVELOPMENT_PATH'] || 'config/keys/development_push.pem'
      "#{Rails.root}/#{file_path}"
    end

    def production_certificate
      file_path = ENV['APN_PRODUCTION_PATH'] || "config/keys/production_push.pem"
      "#{Rails.root}/#{file_path}"
    end
  end
end