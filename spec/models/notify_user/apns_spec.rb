require 'spec_helper'
require 'support/test_apn_connection'

module NotifyUser
  describe Apns do
    let(:user) { create(:user, email: 'user@example.com') }
    let(:notification) { create(:notify_user_notification, params: {}, target: user) }

    describe 'initialisation' do
      before :each do
        @apns = Apns.new([notification], [], {})
      end
    end

    describe 'push' do
      before :each do
        @apns = Apns.new([notification], [], {})

        @connection = TestAPNConnection.new
        @pool = ConnectionPool.new(size: 1) { @connection }
        stub_const("NotifyUser::APNConnection::POOL", @pool)
      end

      context 'with no errors' do
        before :each do
          @mock_status = instance_double("status", status: "200", body: {})
        end

        it 'succeeds if no error' do
          expect(@apns.push).to eq true
        end

        it 'writes to the connection for each device' do
          devices = []
          3.times do
            devices << create_device_double
          end

          allow(@apns).to receive(:devices) { devices }
          expect(@connection).to receive(:write).exactly(3).times { @mock_status }
          @apns.push
        end
      end

      context 'with an error' do
        before :each do
          @mock_status = instance_double("status", status: "400", body: { "reason" => "BadDeviceToken"})
          allow(@connection).to receive(:write) { @mock_status }
        end

        it 'destoys the device that failed' do
          @device = create_device_double
          allow(@apns).to receive(:devices) { [@device] }

          expect(@device).to receive(:destroy) { true }
          @apns.push
        end
      end

      describe 'Delivery logging' do
        before do
          @mock_status = instance_double("status", status: "200", body: {})
          @delivery = instance_double('Delivery')
          @device = create_device_double

          allow(@connection).to receive(:write) { @mock_status }
          allow(@apns).to receive(:devices) { [@device] }
          allow(@apns).to receive(:delivery) { @delivery }
        end

        it 'calls the log method on delivery' do
          expect(@delivery).to receive(:log_response_for_device).with(@device.id, @mock_status)

          @apns.push
        end
      end
    end
  end
end
