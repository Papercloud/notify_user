FactoryGirl.define do
  factory :user do
    sequence :email do |n|
      "#{n}@notifyuser.com"
    end
  end
end
