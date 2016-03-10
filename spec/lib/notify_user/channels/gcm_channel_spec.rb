require 'spec_helper'

describe GcmChannel do
  let(:user) { User.create({email: 'user@example.com' })}
  let(:notification) { NewPostNotification.create({target: user}) }

  before do
    @android = instance_double('Device', token: 'android_token')
    @ios = instance_double('Device', token: 'ios_token')

    allow(notification).to receive(:mobile_message) { 'Message' }

    allow_any_instance_of(NotifyUser::Apns).to receive(:push)
    allow_any_instance_of(NotifyUser::Gcm).to receive(:push)
  end

  describe 'device spliting' do
    context 'all devices' do
      before do
        devices = double('Device', ios: [@ios], android: [@android])
        allow_any_instance_of(User).to receive(:devices) { devices }
      end

      it 'routes the notifications via gcm' do
        @gcm = NotifyUser::Gcm.new([notification], [@android], {})
        expect(NotifyUser::Gcm).to receive(:new) { @gcm }

        described_class.deliver(notification)
      end

      it 'doesnt make use of apns' do
        expect(NotifyUser::Apns).not_to receive(:new)
        described_class.deliver(notification)
      end
    end
  end
end