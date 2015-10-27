FactoryGirl.define do
  factory :notify_user_notification, class: 'NewPostNotification' do
    params {{ data: 'My Data' }}

    association :target, factory: :user
  end
end
