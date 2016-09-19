module NotifyUser
  class Unsubscribe < ActiveRecord::Base
    self.table_name = "notify_user_unsubscribes"

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type

    validates :type, :uniqueness => {:scope => [:target_type, :target_id]}

    self.inheritance_column = :_type_disabled

    class << self
      def for_target(target)
        where(target: target)
      end

      def unsubscribe!(target, type, group_id = nil)
        where(target: target, type: type, group_id: group_id).first_or_create
      end

      # Subscribing means destroying current matching unsubscribe objects:
      def subscribe!(target, type, group_id = nil)
        where(target: target, type: type, group_id: group_id).destroy_all
      end

      def has_unsubscribed_from?(target, type, group_id = nil, channel_name = nil)
        opts = { target: target, type: type, group_id: group_id, channel_name: channel_name }.compact
        exists?(opts)
      end
    end
  end
end
