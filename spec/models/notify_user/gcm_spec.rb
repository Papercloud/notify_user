require 'spec_helper'
require 'support/test_gcm_connection'

module NotifyUser
  describe Gcm, type: :model do
    let(:user) { create(:user) }
    let(:notification) { create(:notify_user_notification, params: {}, target: user) }
    let(:delivery) { create(:delivery, notification: notification) }

    before :each do
      @client = TestGCMConnection.new
      allow_any_instance_of(Gcm).to receive(:client).and_return(@client)
    end

    describe 'push' do
      before :each do
        @gcm = Gcm.new(delivery, {})

        # Mock device fetching:
        @device = create_device_double
        allow(@gcm).to receive(:fetch_device) { @device }
      end

      context 'without errors' do
        before :each do
          @mock_status = {
            body: "{\"multicast_id\":7271457233098108570,\"success\":1,\"failure\":0,\"canonical_ids\":0,\"results\":[{\"message_id\":\"1\"}]}",
            status_code: 200,
            response: "success"
          }

          allow(@client).to receive(:send) { @mock_status }
        end

        it 'sends to the device token of the notification target' do
          expect(@client).to receive(:send).with('token', kind_of(Hash))
          @gcm.push
        end
      end

      context 'with an error' do
        before :each do
          @mock_status = {
            body: "{\"multicast_id\":7271457233098108570,\"success\":0,\"failure\":1,\"canonical_ids\":0,\"results\":[{\"error\":\"InvalidRegistration\"}]}",
            status_code: 200,
            response: "success"
          }

          allow(@client).to receive(:send) { @mock_status }
          allow(@device).to receive(:destroy)
        end

        it 'records the status on the delivery' do
          expect do
            @gcm.push
            delivery.reload
          end.to change(delivery, :status).to '200'
        end

        it 'records the reason on the delivery' do
          expect do
            @gcm.push
            delivery.reload
          end.to change(delivery, :reason).to 'InvalidRegistration'
        end

        it 'removes the bad device' do
          expect(@device).to receive(:destroy) { true }
          @gcm.push
        end
      end
    end
  end
end
