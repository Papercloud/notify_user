require 'spec_helper'

describe NotifyUser::Gcm, type: :model do
  let(:user) { User.create({email: 'user@example.com' })}
  let(:notification) { NewPostNotification.create({target: user}) }

  before :each do
    allow_any_instance_of(NotifyUser::BaseNotification).to receive(:mobile_message).and_return('New Notification')
    allow_any_instance_of(NotifyUser::Gcm).to receive(:device_tokens).and_return('a_token')
  end

  describe "initialisation" do
    it 'initialises the correct push options' do
      @gcm = NotifyUser::Gcm.new([notification], @devices, {})

      expect(@gcm.push_options).to include(data: {
        notification_id: notification.id,
        message: 'New Notification',
        type: 'NewPostNotification',
        unread_count: 1,
        custom_data: {},
      })
    end

    xit "should initialize with many notifications" do
      expect(NotifyUser::BaseNotification).to receive(:aggregate_message).and_return("New Notification")
      notifications = NewPostNotification.create([{target: user}, {target: user}, {target: user}])

      NotifyUser::Gcm.new(notifications, @devices, {})
    end
  end
end