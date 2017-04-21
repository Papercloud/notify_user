require 'spec_helper'

describe GcmChannel do
  class TestNotification < NotifyUser::BaseNotification; end

  let(:user) { User.create({email: 'user@example.com' })}
  let(:notification) { NewPostNotification.create({target: user}) }
  let(:delivery) { create(:delivery, notification: notification) }

  before do
    @gcm = NotifyUser::Gcm.new(delivery, {})
    allow_any_instance_of(NotifyUser::Gcm).to receive(:push)
  end

  describe 'device spliting' do
    it 'routes the notifications via gcm' do
      expect(NotifyUser::Gcm).to receive(:new) { @gcm }

      described_class.deliver(delivery.id)
    end

    it 'doesnt make use of apns' do
      expect(NotifyUser::Apns).not_to receive(:new)
      described_class.deliver(delivery.id)
    end
  end

  context 'with stubbed GCM push and Notification mobile message' do
    describe '.deliver' do
      it 'creates an instance of the Gcm class' do
        expect(NotifyUser::Gcm).to receive(:new)
          .with(delivery, kind_of(Hash))
          .and_call_original

        described_class.deliver(delivery.id, {})
      end

      it 'passes on the options' do
        expect(NotifyUser::Gcm).to receive(:new)
          .with(delivery, hash_including({foo: 'bar'}))
          .and_call_original

        described_class.deliver(delivery.id, {foo: 'bar'})
      end

      it 'pushes the notification' do
        expect_any_instance_of(NotifyUser::Gcm).to receive(:push)

        described_class.deliver(delivery.id, {})
      end

      it 'raises an error if the argument is an actual delivery object' do
        expect do
          described_class.deliver(delivery)
        end.to raise_error RuntimeError
      end
    end
  end
end