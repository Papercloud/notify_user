class APNConnection

  def initialize
    setup
  end

  def setup
    @uri, @certificate = if Rails.env.production?
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

  def write(data)
    begin
      raise "Connection is closed" unless @connection.open?
      @connection.write(data)
    rescue Exception => e
      attempts ||= 0
      attempts += 1

      if attempts < 5
        setup
        retry
      else
        raise e
      end
    end
  end

end