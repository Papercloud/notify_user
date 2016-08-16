require 'spec_helper'

module NotifyUser
  describe NotificationsController, type: :controller do
    let(:user) { create(:user) }

    before :each do
      allow_any_instance_of(NotificationsController).to receive(:current_user).and_return(user)
      allow_any_instance_of(NotificationsController).to receive(:authenticate_user!).and_return(true)
    end

    it 'delegates authentication to Devise' do
      expect(subject).to receive(:authenticate_user!).and_return(true)
      get :index
    end

    describe 'GET notifications.json' do
      render_views

      let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Blobby') }

      before :each do
        notification.save
      end

      it 'returns a message from a rendered template' do
        get :index, format: :json
        expect(json[:notifications][0][:message]).to include 'New Post Notification happened with'
        expect(json[:notifications][0][:message]).to include notification.params[:name]
      end

      it 'returns notification without parent_id set' do
        get :index, format: :json
        expect(json[:notifications].count).to eq 1
      end

      it "doesn't return notifications with a parent_id set" do
        NewPostNotification.create(target: user, parent_id: 1)

        get :index, format: :json
        expect(json[:notifications].count).to eq 1
      end
    end

    describe 'GET web Index notifications' do
      render_views

      let(:notification)  { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Blobby') }
      let(:notification1) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Addams') }
      let(:notification2) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mrs. James') }

      before :each do
        notification.save
        notification1.save
        notification2.save
      end

      it 'returns a list of notifications' do
        allow_any_instance_of(BaseNotification).to receive(:message).and_return('Mr. Blobby')
        get :index
        expect(response.body).to have_content('Mr. Blobby')
      end

      it 'reading a notification marks it as read' do
        expect do
          get :read, id: notification.id
          notification.reload
        end.to change(notification, :read_at).from(nil)
      end

      it 'reading a notification takes to redirect action' do
        get :read, id: notification.id
        expect(response.body).to have_content('set redirect logic')
      end

      it "reading a notification twice doesn't throw an exception" do
        notification.update_attributes(read_at: Time.zone.now)
        expect do
          get :read, id: notification.id
        end.not_to raise_error
      end

      it 'marks all unread messages as read' do
        get :mark_all
        notifications = BaseNotification.for_target(user).where('read_at IS NULL')
        expect(notifications.length).to eq 0
      end
    end

    describe 'PUT notifications/unsubscribe_from_object' do
      it 'unsubscribe returns 201' do
        expect(Unsubscribe).to receive(:unsubscribe)
        put :unsubscribe_from_object, format: :json, subscription: { type: 'NewPostNotification', group_id: 1, unsubscribe: true }
        expect(response.response_code).to eq 201
      end

      it 'subscribe returns 201' do
        expect(Unsubscribe).to receive(:subscribe)
        put :unsubscribe_from_object, format: :json, subscription: { type: 'NewPostNotification', group_id: 1, unsubscribe: false }
        expect(response.response_code).to eq 201
      end
    end

    describe 'PUT notifications/mark_read.json' do
      let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Blobby') }

      before :each do
        notification.save
      end

      it 'marks notifications as read' do
        put :mark_read, ids: [notification.id]
        notification.reload
        expect(notification.read?).to eq true
      end

      it 'returns updated notifications' do
        put :mark_read, ids: [notification.id]
        expect(json[:notifications][0]).not_to be_nil
      end
    end

    describe 'unsubscribing and subscribing' do
      let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Blobby') }

      before :each do
        notification.save
      end

      it 'endpoint for updating notification subscription statuses' do
        expect(Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification')).to eq []
        put :subscriptions, types: [{
          type: 'NewPostNotification',
          status: '0'
        }]
        expect(Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification')).not_to eq []
      end

      it 'endpoint for updating notification subscription statuses passing 1 does nothing' do
        expect(Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification')).to eq []
        put :subscriptions, types: [{
          type: 'NewPostNotification',
          status: '1'
        }]
        expect(Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification')).to eq []
      end

      it 'unsubscribing from notification type' do
        get :unsubscribe, type: 'NewPostNotification'
        expect(Unsubscribe.last.type).to eq 'NewPostNotification'
      end

      it 'subscribing deletes the unsubscribe object' do
        # lack of unsubscribe object implies the user is subscribed
        Unsubscribe.create(target: user, type: 'NewPostNotification')
        get :subscribe, type: 'NewPostNotification'
        expect(Unsubscribe.all).to eq []
      end

      it 'verifies user token before unsubscribe then deactivates that token' do
        user_hash = notification.generate_unsubscribe_hash
        get :unauth_unsubscribe, type: 'NewPostNotification', token: user_hash.token

        user_hash = UserHash.last
        expect(user_hash.active).to eq false
      end
    end
  end
end
