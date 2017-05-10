require 'spec_helper'

module NotifyUser
  describe ReadsController, type: :controller do
    before :each do
      @user = create(:user)
      allow(controller).to receive(:authenticate_user!) { true }
      allow(controller).to receive(:current_user) { @user }
    end

    describe 'POST create' do
      context 'one notification' do
        before :each do
          @notification = create(:notify_user_notification, target: @user)
        end

        it 'responds successfully' do
          post :create, notification_ids: [@notification.id]
          expect(response.status).to eq 201
        end

        it 'marks the notification as read' do
          expect do
            post :create, notification_ids: [@notification.id]
            @notification.reload
          end.to change(@notification, :read_at).from(nil)
        end
      end

      context 'multiple notifications' do
        before :each do
          @notifications = create_list(:notify_user_notification, 2, target: @user)
        end

        it 'responds successfully' do
          post :create, notification_ids: @notifications.map(&:id)
          expect(response.status).to eq 201
        end

        it 'marks the notification as read' do
          expect do
            post :create, notification_ids: @notifications.map(&:id)
            @notifications.map(&:reload)
          end.to change{ @notifications.map(&:read_at)}.from([nil, nil])
        end
      end

      context 'read notification' do
        before :each do
          @notification = create(:notify_user_notification, target: @user, read_at: Time.zone.now)
        end

        it 'responds successfully' do
          post :create, notification_ids: [@notification.id]
          expect(response.status).to eq 201
        end

        it 'doesnt bother updating the read at' do
          Timecop.freeze(Time.zone.now + 5.minutes) do
            expect do
              post :create, notification_ids: [@notification.id]
              @notification.reload
            end.not_to change(@notification.read_at, :to_s)
          end
        end
      end
    end

    describe 'POST create_all' do
      before :each do
        @notifications = create_list(:notify_user_notification, 2, target: @user)
      end

      it 'responds successfully' do
        post :create_all
        expect(response.status).to eq 201
      end

      it 'marks the notification as read' do
        expect do
          post :create_all
          @notifications.map(&:reload)
        end.to change{ @notifications.map(&:read_at)}.from([nil, nil])
      end

      it 'doesnt bother updating the read at of read notifications' do
        read_notification = create(:notify_user_notification, target: @user, read_at: Time.zone.now)
        expect do
          post :create_all
          read_notification.reload
        end.not_to change(read_notification.read_at, :to_s)
      end
    end
  end
end
