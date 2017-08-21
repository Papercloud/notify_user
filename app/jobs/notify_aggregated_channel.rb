require 'que'

class NotifyAggregatedChannel < Que::Job
  def run(klass, id, channel_name)
    klass.notify_aggregated_channel(id, channel_name)
  end
end
