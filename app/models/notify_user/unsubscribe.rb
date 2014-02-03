module NotifyUser
  class Unsubscribe < ActiveRecord::Base
    self.table_name = "notify_user_unsubscribes"

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type
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
  end
end
