require 'spec_helper'

describe NotifyUser::Factories::Gcm do
  describe '#present' do
    before :each do
      user = create(:user)
      @notification = create_notification_for_user(user)
    end

    describe '.build' do
      before :each do
        @gcm = described_class.build(@notification, {})
      end

      it 'sets the notification id' do
        expect(@gcm[:data][:notification_id]).to eq @notification.id
      end

      it 'sets the mobile message' do
        expect(@gcm[:data][:message]).to eq 'New Post Notification happened with {}'
      end

      it 'sets the badge to 1' do
        expect(@gcm[:data][:unread_count]).to eq 1
      end

      it 'sets the notification category' do
        expect(@gcm[:data][:type]).to eq 'NewPostNotification'
      end

      it 'sets the custom data with params' do
        expect(@gcm[:data][:custom_data]).to eq({})
      end
    end
  end

  def create_notification_for_user(user, options = {})
    NewPostNotification.create({ target: user }.merge(options))
  end
end
