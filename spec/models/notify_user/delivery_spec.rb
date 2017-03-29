require 'spec_helper'

module NotifyUser
  describe Delivery, type: :model do
    describe 'validations' do
      it { should validate_presence_of(:notification) }
      it { should validate_presence_of(:deliver_in) }
      it { should validate_presence_of(:channel) }
    end

    describe 'delivering' do
      before :each do
        @notification = create(:notify_user_notification)

        allow(@notification.class).to receive(:channels) {{
          apns: { aggregate_per: [0, 3, 10, 30, 60] }
        }}
      end

      it 'schedules a delivery worker for the channel' do
        delivery = build(:delivery, deliver_in: 0, notification: @notification, channel: 'apns', id: 3749)

        TestAfterCommit.with_commits(true) do
          expect(NotifyUser::DeliveryWorker).to receive(:perform_in).with(0.seconds, 3749)
          delivery.save
        end
      end
    end

    describe '#log_response_for_device' do
      let!(:delivery) { create(:delivery) }
      let(:device) { create_device_double }
      let(:response) { instance_double('status', status: '200', body: {}) }

      subject { delivery.log_response_for_device(device, response) }

      context 'No previous responses' do
        it 'updates the responses of the delivery' do
          expect do
            subject
            delivery.reload
          end.to change(delivery, :responses).to({ device.id => { 'status' => '200', 'body' => {} } })
        end
      end

      context 'with previous responses' do
        before do
          delivery.update(responses: { '1234' => { status: 400 } })
        end

        it 'merges the responses hash' do
          expect do
            subject
            delivery.reload
          end.to change(delivery, :responses).to({"1234"=>{"status"=>400}, "1"=>{"status"=>"200", "body"=>{}}})
        end
      end
    end
  end
end
