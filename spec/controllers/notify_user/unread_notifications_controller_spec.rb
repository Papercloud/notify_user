require 'spec_helper'

module NotifyUser
  describe UnreadNotificationsController, type: :controller do
    before :each do
      @user = create(:user)
      allow(controller).to receive(:authenticate_user!) { true }
      allow(controller).to receive(:current_user) { @user }
    end

    describe 'GET index_count' do
      it 'responds successfully' do
        create(:notify_user_notification, target: @user)
        create(:notify_user_notification, target: @user, read_at: Time.zone.now)

        get :index_count
        expect(response.status).to eq 200
      end

      it 'returns the number of unread notifications' do
        create(:notify_user_notification, target: @user)
        create(:notify_user_notification, target: @user, read_at: Time.zone.now)

        get :index_count
        expect(json[:count]).to eq 1
      end

      it 'returns a maximum count of 100' do
        notifications = double('NotfyUser::BaseNotification', limit: [], count: 100)
        allow(controller).to receive(:collection) { notifications }

        get :index_count
        expect(json[:count]).to eq 100
      end
    end
  end
end
