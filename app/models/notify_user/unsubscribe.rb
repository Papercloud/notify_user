module NotifyUser
  class Unsubscribe < ActiveRecord::Base
    self.table_name = "notify_user_unsubscribes"

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type

    validate :is_unsubscribable

    validates :type, :uniqueness => {:scope => :target}

    self.inheritance_column = :_type_disabled

    if Rails.version.to_i < 4 || !StrongParameters
      attr_accessible :target, :type
    end

    def self.for_target(target)
      where(target_id: target.id)
      .where(target_type: target.class.base_class)
    end

    def self.toggle_status(target, type)
      if NotifyUser::Unsubscribe.has_unsubscribed_from(target, type).empty?
        NotifyUser::Unsubscribe.create(target: target, type: type)
      else
        NotifyUser::Unsubscribe.where(target: target, type: type).destroy_all
      end 
    end

    def self.has_unsubscribed_from(target, type)
      where(target_id: target.id)
      .where(target_type: target.class.base_class)
      .where(type: type)
    end

    private

    #only throw error if both are false
    def is_unsubscribable
      errors.add(:type, ("not found")) if (NotifyUser.unsubscribable_notifications.include? self.type) == false && 
                            NotifyUser::BaseNotification.channels.has_key?(self.type.to_sym) == false
    end

  end
end
