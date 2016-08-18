require 'spec_helper'

describe ApnsChannel do
  class TestNotification < NotifyUser::BaseNotification; end

  let(:user) { User.create({email: 'user@example.com' })}
  let(:notification) { NewPostNotification.create({target: user}) }

  before do
    @android = instance_double('Device', token: 'android_token')
    @ios = instance_double('Device', token: 'ios_token')

    allow(notification).to receive(:mobile_message) { 'Message' }

    allow_any_instance_of(NotifyUser::Apns).to receive(:push)

    @devices = double('Device', ios: [@ios], android: [@android])
    allow_any_instance_of(User).to receive(:devices) { @devices }

    @apns = NotifyUser::Apns.new([notification], [@ios], {})
  end

  describe 'device spliting' do
    it 'routes the notifications via apns' do
      expect(NotifyUser::Apns).to receive(:new) { @apns }

      described_class.deliver(notification.id)
    end

    it 'doesnt make use of GCM' do
      expect(NotifyUser::Gcm).not_to receive(:new)

      described_class.deliver(notification.id)
    end
  end

  context 'with stubbed Apns push and Notification mobile message' do
    before :each do
      allow_any_instance_of(NotifyUser::Apns).to receive(:push)
      allow_any_instance_of(TestNotification).to receive(:mobile_message) { 'Notification message' }
    end

    describe '.deliver' do
      let!(:notification) { TestNotification.create({target: create(:user)}) }

      it 'creates an instance of the Apns class' do
        expect(NotifyUser::Apns).to receive(:new)
          .with([notification], kind_of(Array), kind_of(Hash))
          .and_call_original

        described_class.deliver(notification.id, {})
      end

      it 'passes on the options' do
        expect(NotifyUser::Apns).to receive(:new)
          .with([notification], kind_of(Array), hash_including({foo: 'bar'}))
          .and_call_original

        described_class.deliver(notification.id, {foo: 'bar'})
      end

      it 'pushes the notification' do
        expect_any_instance_of(NotifyUser::Apns).to receive(:push)

        described_class.deliver(notification.id, {})
      end

      it 'raises an error if the argument is an actual notification object' do
        expect do
          described_class.deliver(notification)
        end.to raise_error RuntimeError
      end
    end

    describe '.deliver_aggregated' do
      let!(:notifications) { 3.times.map { TestNotification.create({target: user}) } }

      it 'creates an instance of the Apns class' do
        expect(NotifyUser::Apns).to receive(:new)
          .with(notifications, kind_of(Array), kind_of(Hash))
          .and_call_original

        described_class.deliver_aggregated(notifications.map(&:id), {})
      end

      it 'passes on the options' do
        expect(NotifyUser::Apns).to receive(:new)
          .with(notifications, kind_of(Array), hash_including({foo: 'bar'}))
          .and_call_original

        described_class.deliver_aggregated(notifications.map(&:id), {foo: 'bar'})
      end

      it 'pushes the notification' do
        expect_any_instance_of(NotifyUser::Apns).to receive(:push)

        described_class.deliver_aggregated(notifications.map(&:id), {})
      end

      it 'raises an error if the argument is actual notification objects' do
        expect do
          described_class.deliver_aggregated(notifications)
        end.to raise_error RuntimeError
      end
    end
  end
end