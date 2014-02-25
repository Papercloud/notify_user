module NotifyUser
  class UserHash < ActiveRecord::Base
    self.table_name = "notify_user_user_hashes"

    attr_accessible :target, :type, :active

    # The user to send the notification to
    belongs_to :target, polymorphic: true

    validates_presence_of :target_id, :target_type, :target, :type

    before_create :generate_token

    self.inheritance_column = :_type_disabled

    if Rails.version.to_i < 4
      attr_accessible :target, :type, :active
    end

    def self.confirm_hash(token, type)
      return NotifyUser::UserHash.exists?(token: token, type: type, active: true)
    end

    def deactivate
      self.active = false
      save
    end

    private
    def generate_token
      self.token = loop do
        random_token = SecureRandom.urlsafe_base64(nil, false) + SecureRandom.urlsafe_base64(nil, false)
        break random_token unless NotifyUser::UserHash.exists?(token: random_token)
      end
    end

  end
end
