module NotifyUser
  class Delivery < ActiveRecord::Base
    self.table_name = "notify_user_deliveries"

    validates :notification, presence: true
    validates :channel, presence: true
    validates :deliver_in, presence: true

    belongs_to :notification, class_name: BaseNotification.name

    after_commit :deliver!, on: :create

    private

    def deliver!
      DeliveryWorker.perform_in(deliver_in, id)
    end
  end
end
