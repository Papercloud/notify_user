require 'que'

class DeliverNotificationChannel < Que::Job
  def run(klass, id, channel_name)
    klass.deliver_notification_channel(id, channel_name)
  end
end
