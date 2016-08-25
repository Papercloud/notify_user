require 'spec_helper'

describe ActionMailerChannel do
  class TestNotification < NotifyUser::BaseNotification; end

  before :each do
    allow_any_instance_of(ActionMailer::Base).to receive(:deliver)
    @fake_mailer = instance_double('ActionMailer::Base', deliver: true)
  end

  describe '.deliver' do
    let!(:notification) { TestNotification.create({target: create(:user)}) }

    it 'calls the notification mailer' do
      expect(NotifyUser::NotificationMailer).to receive(:notification_email)
        .with(notification, kind_of(Hash)) { @fake_mailer }

      described_class.deliver(notification.id, {})
    end

    it 'passes on the options' do
      expect(NotifyUser::NotificationMailer).to receive(:notification_email)
        .with(notification, hash_including({foo: 'bar'})) { @fake_mailer }

      described_class.deliver(notification.id, {foo: 'bar'})
    end

    it 'delivers the mail' do
      allow(NotifyUser::NotificationMailer).to receive(:notification_email) { @fake_mailer }

      expect(@fake_mailer).to receive(:deliver)

      described_class.deliver(notification.id, {})
    end

    it 'raises an error if the argument is an actual notification object' do
      expect do
        described_class.deliver(notification)
      end.to raise_error RuntimeError
    end
  end

  describe '.deliver_aggregated' do
    let(:user) { create(:user) }
    let!(:notifications) { 3.times.map { TestNotification.create({target: user}) } }

    it 'calls the notification mailer' do
      expect(NotifyUser::NotificationMailer).to receive(:aggregate_notifications_email)
        .with(notifications, kind_of(Hash))
        .exactly(1).times { @fake_mailer }

      described_class.deliver_aggregated(notifications.map(&:id), {})
    end

    it 'passes on the options' do
      expect(NotifyUser::NotificationMailer).to receive(:aggregate_notifications_email)
        .with(notifications, hash_including({foo: 'bar'})) { @fake_mailer }

      described_class.deliver_aggregated(notifications.map(&:id), {foo: 'bar'})
    end

    it 'delivers the mail' do
      allow(NotifyUser::NotificationMailer).to receive(:aggregate_notifications_email) { @fake_mailer }

      expect(@fake_mailer).to receive(:deliver)

      described_class.deliver_aggregated(notifications.map(&:id), {})
    end

    it 'raises an error if the argument is actual notification objects' do
      expect do
        described_class.deliver_aggregated(notifications)
      end.to raise_error RuntimeError
    end
  end
end