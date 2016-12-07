require 'apnotic'

module NotifyUser
  module Factories
    module Apns
      include Base

      def self.build(notification, token, options = {})
        buildable = Apnotic::Notification.new(token)
        buildable.alert = fetch_message(notification)
        buildable.badge = count_for_target(notification.target)
        buildable.category = notification.params[:category] || notification.type
        buildable.sound = options[:sound] || 'default'
        buildable.custom_payload = { "custom_data" => notification.sendable_params }
        buildable.topic = ENV['APN_TOPIC']

        return buildable
      end

      def self.build_silent(notification, token, options)
        buildable = Apnotic::Notification.new(token)
        buildable.alert = ''
        buildable.category = notification.params[:category] || notification.type
        buildable.sound = ''
        buildable.content_available = true
        buildable.custom_payload = { "custom_data" => notification.sendable_params }
        buildable.topic = ENV['APN_TOPIC']

        return buildable
      end
    end
  end
end
