require 'spec_helper'

describe NotifyUser::Factories::Apns do
  describe '#present' do
    before :each do
      user = create(:user)
      @notification = create_notification_for_user(user)
      allow(ENV).to receive(:[]).with('APN_TOPIC') { 'au.com.notify_user' }
    end

    describe '.build' do
      before :each do
        @apns = described_class.build(@notification, 'token', {})
      end

      it 'sets the device token' do
        expect(@apns.token).to eq 'token'
      end

      it 'sets the mobile message' do
        expect(@apns.alert).to eq 'New Post Notification happened with {}'
      end

      it 'sets the badge to 1' do
        expect(@apns.badge).to eq 1
      end

      it 'sets the notification category' do
        expect(@apns.category).to eq 'NewPostNotification'
      end

      it 'sets the custom data with params' do
        expect(@apns.custom_payload).to eq({"custom_data"=>{}})
      end

      it 'has a default sound' do
        expect(@apns.sound).to eq 'default'
      end

      it 'can use custom sounds' do
        apns = described_class.build(@notification, 'token', { sound: 'chirp.wav' })

        expect(apns.sound).to eq 'chirp.wav'
      end

      it 'sets the topic' do
        expect(@apns.topic).to eq 'au.com.notify_user'
      end
    end

    describe '.build_silent' do
      before :each do
        @apns = described_class.build_silent(@notification, 'token', {})
      end

      it 'sets the device token' do
        expect(@apns.token).to eq 'token'
      end

      it 'sets a blank alert' do
        expect(@apns.alert).to eq ''
      end

      it 'sets no badge' do
        expect(@apns.badge).to eq nil
      end

      it 'sets the notification category' do
        expect(@apns.category).to eq 'NewPostNotification'
      end

      it 'sets the custom data with params' do
        expect(@apns.custom_payload).to eq({"custom_data"=>{}})
      end

      it 'has no sound' do
        expect(@apns.sound).to eq ''
      end

      it 'sets the content available flag' do
        expect(@apns.content_available).to eq true
      end

      it 'sets the topic' do
        expect(@apns.topic).to eq 'au.com.notify_user'
      end
    end
  end

  def create_notification_for_user(user, options = {})
    NewPostNotification.create({ target: user }.merge(options))
  end
end
