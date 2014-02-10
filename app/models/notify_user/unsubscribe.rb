module NotifyUser
  class Unsubscribe < ActiveRecord::Base
    self.table_name = "notify_user_unsubscribes"

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type

    validate :is_unsubscribale

    # validates :type, :uniqueness => {:scope => :target}

    self.inheritance_column = :_type_disabled

    if ActiveRecord::VERSION::MAJOR < 4
      attr_accessible :target, :type
    end

    def self.for_target(target)
      where(target_id: target.id)
      .where(target_type: target.class.base_class)
    end

    def self.has_unsubscribed_from(target, type)
      where(target_id: target.id)
      .where(target_type: target.class.base_class)
      .where(type: type)
    end

    private
    def is_unsubscribale
      errors.add(:type, ("not found")) if NotifyUser.unsubscribable_notifications.include? self.type && NotifyUser::BaseNotification.channels.has_key?(self.type.to_sym)
    end

  end
end
