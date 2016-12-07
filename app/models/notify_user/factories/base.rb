module NotifyUser
  module Factories
    module Base
      SYMBOL_NAMES_SIZE = 10
      PAYLOAD_LIMIT = 255

      def self.included(including_class)
        including_class.extend ClassMethods
      end

      module ClassMethods
        private

        # Get the message from the notification presenter:
        def mobile_message(notification, length)
          ChannelPresenter.present(notification, length)
        end

        # Get the unread count for the badge:
        def count_for_target(target)
          BaseNotification.unread_count_for_target(target)
        end

        # Get the actual message to send through the pipe:
        def fetch_message(notification)
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
        def used_space(notification)
          used_space = SYMBOL_NAMES_SIZE + notification.id.size + notification.created_at.to_time.to_i.size +
                        notification.type.size

          used_space += notification.params[:action_id].size if notification.params[:action_id]

          used_space
        end
      end
    end
  end
end
