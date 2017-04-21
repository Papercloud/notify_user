require 'spec_helper'

RSpec.describe NotifyUser::DeliveryWorker, type: :model do
  describe 'perform' do
    subject do
      described_class.new
    end

    before :each do
      allow(ApnsChannel).to receive(:deliver)
    end

    it 'performs delivery via the required channel' do
      notification = create(:notify_user_notification)
      delivery = create(:delivery, notification: notification, channel: 'apns')

      expect(ApnsChannel).to receive(:deliver).with(delivery.id, anything)
      subject.perform(delivery.id)
    end

    it 'sets the send time on the delivery' do
      notification = create(:notify_user_notification)
      delivery = create(:delivery, notification: notification, channel: 'apns')

      expect do
        subject.perform(delivery.id)
        delivery.reload
      end.to change(delivery, :sent_at).from(nil)
    end

    it 'doesnt perform delivery if the notification has already been read' do
      notification = create(:notify_user_notification, read_at: Time.zone.now)
      delivery = create(:delivery, notification: notification, channel: 'apns')

      expect(ApnsChannel).not_to receive(:deliver)
      subject.perform(delivery.id)
    end
  end
end
