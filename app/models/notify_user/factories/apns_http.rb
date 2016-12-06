module NotifyUser
  module Factories
    module ApnsHttp
      SYMBOL_NAMES_SIZE = 10
      PAYLOAD_LIMIT = 255

      def self.build(notification, device, options)
        buildable = Apnotic::Notification.new(device.token)
        buildable.alert = fetch_message(notification)
        buildable.badge = count_for_target(notification.target)
        buildable.category = notification.params[:category] || notification.type,
        buildable.sound = options[:sound] || 'default'
        buildable.custom_payload = notification.sendable_params
        buildable.topic = ENV['APN_TOPIC']

        return buildable
      end

      def self.build_silent(notification, device, options)
        buildable = Apnotic::Notification.new(device.token)
        buildable.alert = ''
        buildable.category = notification.params[:category] || notification.type,
        buildable.sound = ''
        buildable.content_available = true
        buildable.custom_payload = notification.sendable_params
        buildable.topic = ENV['APN_TOPIC']

        return buildable
      end

      private

      def self.mobile_message(notification, length)
        ChannelPresenter.present(notification, length)
      end

      def self.count_for_target(target)
        BaseNotification.unread_count_for_target(target)
      end

      def self.fetch_message(notification)
        space_allowance = PAYLOAD_LIMIT - used_space(notification)

        mobile_message = ''
        if notification.parent_id
          parent = notification.class.find(notification.parent_id)
          mobile_message = mobile_message(parent, space_allowance)
        else
          mobile_message = mobile_message(notification, space_allowance)
        end
        mobile_message.gsub!('\n', "\n")

        return mobile_message
      end

      # Calculates the bytes already used:
      def self.used_space(notification)
        used_space = SYMBOL_NAMES_SIZE + notification.id.size + notification.created_at.to_time.to_i.size +
                      notification.type.size

        used_space += notification.params[:action_id].size if notification.params[:action_id]

        used_space
      end
    end
  end
end
