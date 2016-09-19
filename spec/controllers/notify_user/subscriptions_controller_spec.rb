require 'spec_helper'

module NotifyUser
  describe SubscriptionsController, type: :controller do
    before :each do
      @user = create(:user)
      allow(controller).to receive(:authenticate_user!) { true }
      allow(controller).to receive(:current_user) { @user }
    end

    describe 'GET index' do
      it 'returns successfully' do
        get :index
        expect(response.status).to eq 200
      end

      it 'returns all subscriptions' do
        Unsubscribe.unsubscribe!(@user, 'NewPostNotification')

        get :index
        expect(json.length).to eq 1
      end
    end

    describe 'POST create' do
      it 'returns successfully' do
        post :create, type: 'NewPostNotification'
        expect(response.status).to eq 201
      end

      it 'removes any unsubscribes for the user' do
        Unsubscribe.unsubscribe!(@user, 'NewPostNotification')
        expect do
          post :create, type: 'NewPostNotification'
        end.to change(Unsubscribe.for_target(@user).where(type: 'NewPostNotification'), :count).by(-1)
      end
    end

    describe 'PUT update_batch' do
      it 'returns successfully' do
        put :update_batch, types: [{ type: 'NewPostNotification', status: '0' }]
        expect(response.status).to eq 200
      end

      it 'unsubscribes when 0 status is passed' do
        expect do
          put :update_batch, types: [{ type: 'NewPostNotification', status: '0' }]
        end.to change(Unsubscribe.for_target(@user).where(type: 'NewPostNotification'), :count).by(1)
      end

      it 'subscribes when 0 status is passed' do
        Unsubscribe.unsubscribe!(@user, 'NewPostNotification')
        expect do
          put :update_batch, types: [{ type: 'NewPostNotification', status: '1' }]
        end.to change(Unsubscribe.for_target(@user).where(type: 'NewPostNotification'), :count).by(-1)
      end
    end

    describe 'DELETE destroy' do
      it 'returns successfully' do
        delete :destroy, type: 'NewPostNotification'
        expect(response.status).to eq 200
      end

      it 'creates a unsubscribe for the user' do
        expect do
          delete :destroy, type: 'NewPostNotification'
        end.to change(Unsubscribe.for_target(@user).where(type: 'NewPostNotification'), :count).by(1)
      end
    end
  end
end
