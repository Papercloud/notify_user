require 'apnotic'

module NotifyUser
  class APNHttpConnection

    POOL = ConnectionPool.new(
      size: (ENV['APNS_CONNECTION_POOL_SIZE'] ? ENV['APNS_CONNECTION_POOL_SIZE'].to_i : 1),
      timeout: (ENV['APNS_CONNECTION_TIMEOUT'] ? ENV['APNS_CONNECTION_TIMEOUT'].to_i : 30)) {
      APNHttpConnection.new
    }

    def initialize
      connection
    end

    def connection
      @connection ||= setup_connection
    end

    def write(notification)
      @connection.push(notification)
    end

    private

    def apn_environment
      return nil unless ENV['APN_ENVIRONMENT']

      ENV['APN_ENVIRONMENT'].downcase.to_sym
    end

    def setup_connection
      return if Rails.env.test?

      certificate = if Rails.env.development? || apn_environment == :development
        Rails.logger.info "Using development gateway. Rails env: #{Rails.env}, APN_ENVIRONMENT: #{apn_environment}"
        production_certificate#development_certificate
      else
        Rails.logger.info "Using production gateway. Rails env: #{Rails.env}, APN_ENVIRONMENT: #{apn_environment}"
        production_certificate
      end

      @connection = Apnotic::Connection.new(cert_path: certificate)
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