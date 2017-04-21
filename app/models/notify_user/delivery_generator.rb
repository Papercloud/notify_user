module NotifyUser
  class DeliveryGenerator
    def generate(notification, options)
      Delivery.create!(options)
    end

    def self.for(channel)
      begin
        const_get("NotifyUser::#{channel.camelize}DeliveryGenerator")
      rescue NameError
        DeliveryGenerator
      end.new
    end
  end

  class ApnsDeliveryGenerator < DeliveryGenerator
    def generate(notification, options)
      fetch_device_tokens(notification).each do |token|
        Delivery.create!(options.merge(device_token: token))
      end
    end

    private

    def fetch_device_tokens(notification)
      # TODO: Figure out how to make this configureable, at the moment it's locked to how Dre works:
      devices = notification.target.devices
      devices.ios.pluck(:token)
    rescue
      Rails.logger.info "Notification target, #{notification.target.class}, does not respond to the method, #devices."
      []
    end
  end

  class GcmDeliveryGenerator < DeliveryGenerator
    def generate(notification, options)
      fetch_device_tokens(notification).each do |token|
        Delivery.create!(options.merge(device_token: token))
      end
    end

    private

    def fetch_device_tokens(notification)
      # TODO: Figure out how to make this configureable, at the moment it's locked to how Dre works:
      devices = notification.target.devices
      devices.android.pluck(:token)
    rescue
      Rails.logger.info "Notification target, #{notification.target.class}, does not respond to the method, #devices."
      []
    end
  end
end
