require 'spec_helper'
require 'support/test_apn_connection'

module NotifyUser
  describe Apns do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:notification) { create(:notify_user_notification, params: {}, target: user) }
    let(:delivery) { create(:delivery, notification: notification) }

    describe 'push' do
      before :each do
        @apns = Apns.new(delivery, {})

        # Mock device fetching:
        @device = create_device_double
        allow(@apns).to receive(:fetch_device) { @device }

        # Mock connection pool:
        @connection = TestAPNConnection.new
        @pool = ConnectionPool.new(size: 1) { @connection }
        stub_const("NotifyUser::APNConnection::POOL", @pool)
      end

      context 'with no errors' do
        before :each do
          @mock_status = instance_double("status", status: "200", body: {})
          allow(@connection).to receive(:write) { @mock_status }
        end

        it 'records the status on the delivery' do
          expect do
            @apns.push
            delivery.reload
          end.to change(delivery, :status).to '200'
        end
      end

      context 'with an error' do
        before :each do
          @mock_status = instance_double("status", status: "400", body: { "reason" => "BadDeviceToken" })
          allow(@connection).to receive(:write) { @mock_status }
          allow(@device).to receive(:destroy)
        end

        it 'records the status on the delivery' do
          expect do
            @apns.push
            delivery.reload
          end.to change(delivery, :status).to '400'
        end

        it 'records the reason on the delivery' do
          expect do
            @apns.push
            delivery.reload
          end.to change(delivery, :reason).to 'BadDeviceToken'
        end

        it 'removes the bad device' do
          expect(@device).to receive(:destroy) { true }
          @apns.push
        end
      end
    end
  end
end
