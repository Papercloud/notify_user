FactoryGirl.define do
  factory :delivery, class: NotifyUser::Delivery.name do
    deliver_in 0
    channel 'apns'
    association :notification, factory: :notify_user_notification
  end
end
