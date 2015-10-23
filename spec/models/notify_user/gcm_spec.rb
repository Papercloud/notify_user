require 'spec_helper'

module NotifyUser
  describe Gcm, type: :model do
    let(:user) { User.create({email: 'user@example.com' })}
    let(:notification) { NewPostNotification.create({target: user}) }
    let(:user_tokens) { ['a_token'] }

    before :each do
      allow_any_instance_of(NotifyUser::BaseNotification).to receive(:mobile_message).and_return('New Notification')
      allow_any_instance_of(NotifyUser::Gcm).to receive(:device_tokens).and_return(user_tokens)
    end

    describe "initialisation" do
      it 'initialises the correct push options' do
        @gcm = NotifyUser::Gcm.new([notification], [], {})

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

        NotifyUser::Gcm.new(notifications, [], {})
      end
    end

    describe 'push' do
      before :each do
        @gcm = Gcm.new([notification], [], {})
      end

      it 'sends to the device token of the notification target' do
        expect_any_instance_of(GCM).to receive(:send).with(user_tokens, kind_of(Hash))
        @gcm.push
      end

      it 'does not try to send to an empty token' do
        user_tokens = []
        allow_any_instance_of(NotifyUser::Gcm).to receive(:device_tokens).and_return(user_tokens)
        expect_any_instance_of(GCM).not_to receive(:send)
        @gcm.push
      end
    end
  end
end