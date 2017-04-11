require 'spec_helper'

module NotifyUser
  describe DeliveryGenerator do
    describe '.for' do
      it 'returns a default generator' do
        expect(DeliveryGenerator.for('action_mailer').class).to eq DeliveryGenerator
      end

      it 'returns a apns delivery generator' do
        expect(DeliveryGenerator.for('apns').class).to eq ApnsDeliveryGenerator
      end

      it 'returns a gcm delivery generator' do
        expect(DeliveryGenerator.for('gcm').class).to eq GcmDeliveryGenerator
      end
    end

    describe '#generate' do
      let(:target) { create(:user) }
      let(:notification) {  NewPostNotification.create({ target: target }) }
      let(:options) {{ channel: 'action_mailer' , deliver_in: '0', notification: notification }}

      it 'returns a delivery' do
        generator = DeliveryGenerator.new
        expect{ generator.generate(notification, options) }.to change(Delivery, :count).by(1)
      end
    end
  end

  describe ApnsDeliveryGenerator do
    describe '#generate' do
      let(:target) { create(:user) }
      let(:notification) {  NewPostNotification.create({ target: target }) }
      let(:options) {{ channel: 'apns' , deliver_in: '0', notification: notification }}

      it 'creates no delivery if the user has no devices' do
        generator = ApnsDeliveryGenerator.new
        allow(generator).to receive(:fetch_device_tokens) { [] }

        expect{ generator.generate(notification, options) }.not_to change(Delivery, :count)
      end

      it 'creates a delivery if the user has a device' do
        generator = ApnsDeliveryGenerator.new
        allow(generator).to receive(:fetch_device_tokens) { ['test'] }

        expect{ generator.generate(notification, options) }.to change(Delivery, :count).by(1)
      end

      it 'creates multiple deliveries if the user has multiple devices' do
        generator = ApnsDeliveryGenerator.new
        allow(generator).to receive(:fetch_device_tokens) { ['test', 'test'] }

        expect{ generator.generate(notification, options) }.to change(Delivery, :count).by(2)
      end
    end
  end

  describe GcmDeliveryGenerator do
    describe '#generate' do
      let(:target) { create(:user) }
      let(:notification) {  NewPostNotification.create({ target: target }) }
      let(:options) {{ channel: 'apns' , deliver_in: '0', notification: notification }}

      it 'creates no delivery if the user has no devices' do
        generator = GcmDeliveryGenerator.new
        allow(generator).to receive(:fetch_device_tokens) { [] }

        expect{ generator.generate(notification, options) }.not_to change(Delivery, :count)
      end

      it 'creates a delivery if the user has a device' do
        generator = GcmDeliveryGenerator.new
        allow(generator).to receive(:fetch_device_tokens) { ['test'] }

        expect{ generator.generate(notification, options) }.to change(Delivery, :count).by(1)
      end

      it 'creates multiple deliveries if the user has multiple devices' do
        generator = GcmDeliveryGenerator.new
        allow(generator).to receive(:fetch_device_tokens) { ['test', 'test'] }

        expect{ generator.generate(notification, options) }.to change(Delivery, :count).by(2)
      end
    end
  end
end