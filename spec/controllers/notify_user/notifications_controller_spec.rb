require 'spec_helper'

module NotifyUser
  describe NotificationsController, type: :controller do
    before :each do
      @user = create(:user)
      allow(controller).to receive(:authenticate_user!) { true }
      allow(controller).to receive(:current_user) { @user }
    end

    describe 'GET index' do
      render_views

      context '.json' do
        it 'returns a message from a rendered template' do
          create(:notify_user_notification, target: @user, params: { name: 'Mr. Blobby' })

          get :index, format: :json
          expect(json[:notifications][0][:message]).to include 'New Post Notification happened with'
          expect(json[:notifications][0][:message]).to include 'Mr. Blobby'
        end

        it 'returns notification without parent_id set' do
          create(:notify_user_notification, target: @user, params: { name: 'Mr. Blobby' })

          get :index, format: :json
          expect(json[:notifications].length).to eq 1
        end

        it 'doesnt return notifications with a parent_id set' do
          create(:notify_user_notification, target: @user, params: { name: 'Mr. Blobby' }, parent_id: 1)

          get :index, format: :json
          expect(json[:notifications].length).to eq 0
        end
      end
    end

    describe 'GET index.html' do
      render_views

      it 'returns a list of notifications' do
        create(:notify_user_notification, target: @user, params: { name: 'Mr. Blobby' })
        allow_any_instance_of(BaseNotification).to receive(:message).and_return('Mr. Blobby')

        get :index
        expect(response.body).to include 'Mr. Blobby'
      end
    end
  end
end
