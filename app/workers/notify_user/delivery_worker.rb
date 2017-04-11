module NotifyUser
  class DeliveryWorker
    include Sidekiq::Worker

    def perform(delivery_id)
      delivery = Delivery.find(delivery_id)

      if delivery.notification.read?
        # TODO: Log things out
      else
        channel_name = delivery.channel
        channel_options = delivery.notification.class.channels[channel_name.to_sym] || {}
        channel_class = (channel_name + "_channel").camelize.constantize

        channel_class.deliver(delivery.id, channel_options)
        delivery.update(sent_at: Time.zone.now)
      end
    end
  end
end
