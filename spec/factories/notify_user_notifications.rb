# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notify_user_notification, :class => 'Notification' do
    type ""
    target_id 1
    target_type "MyString"
    params "MyText"
  end
end
