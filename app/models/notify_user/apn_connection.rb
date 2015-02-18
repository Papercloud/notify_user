class APNConnection

  def initialize
    setup
  end

  def setup
    @uri, @certificate = if Rails.env.production? || Rails.env.staging?
      [
        Houston::APPLE_PRODUCTION_GATEWAY_URI,
        File.read("#{Rails.root}/config/keys/production_push.pem")
      ]
    else
      [
        Houston::APPLE_DEVELOPMENT_GATEWAY_URI,
        File.read("#{Rails.root}/config/keys/development_push.pem")
      ]
    end

    @connection = Houston::Connection.new(@uri, @certificate, nil)
    @connection.open
  end

  def ssl
    @connection.ssl
  end

  def connection
    @connection
  end

  def write(data)
    raise "Connection is closed" unless @connection.open?
    @connection.write(data)
  end

end