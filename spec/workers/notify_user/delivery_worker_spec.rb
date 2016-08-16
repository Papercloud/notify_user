require 'spec_helper'

RSpec.describe NotifyUser::DeliveryWorker, type: :model do
  describe 'perform' do
    subject do
      described_class.new
    end

    it 'performs delivery via the required channel' do
      notification = create(:notify_user_notification)
      delivery = create(:delivery, notification: notification, channel: 'apns')

      expect(ApnsChannel).to receive(:deliver).with(notification.id, anything)
      subject.perform(delivery.id)
    end

    it 'doesnt perform delivery if the notification has already been read' do
      notification = create(:notify_user_notification, read_at: Time.zone.now)
      delivery = create(:delivery, notification: notification, channel: 'apns')

      expect(ApnsChannel).not_to receive(:deliver)
      subject.perform(delivery.id)
    end
  end
end
