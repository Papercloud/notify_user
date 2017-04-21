require 'spec_helper'

describe ApnsChannel do
  class TestNotification < NotifyUser::BaseNotification; end

  let(:user) { User.create({email: 'user@example.com' })}
  let(:notification) { NewPostNotification.create({target: user}) }
  let(:delivery) { create(:delivery, notification: notification) }

  before :each do
    @apns = NotifyUser::Apns.new(delivery, {})
    allow_any_instance_of(NotifyUser::Apns).to receive(:push)
  end

  describe 'device spliting' do
    it 'routes the notifications via APNS' do
      expect(NotifyUser::Apns).to receive(:new) { @apns }

      described_class.deliver(delivery.id)
    end

    it 'doesnt make use of GCM' do
      expect(NotifyUser::Gcm).not_to receive(:new)

      described_class.deliver(delivery.id)
    end
  end

  context 'with stubbed APNS push and Notification mobile message' do
    before :each do
      allow_any_instance_of(NotifyUser::Apns).to receive(:push)
      allow_any_instance_of(TestNotification).to receive(:mobile_message) { 'Notification message' }
    end

    describe '.deliver' do
      it 'creates an instance of the Apns class' do
        expect(NotifyUser::Apns).to receive(:new)
          .with(delivery, kind_of(Hash))
          .and_call_original

        described_class.deliver(delivery.id, {})
      end

      it 'passes on the options' do
        expect(NotifyUser::Apns).to receive(:new)
          .with(delivery, hash_including({foo: 'bar'}))
          .and_call_original

        described_class.deliver(delivery.id, { foo: 'bar' })
      end

      it 'pushes the notification' do
        expect_any_instance_of(NotifyUser::Apns).to receive(:push)

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