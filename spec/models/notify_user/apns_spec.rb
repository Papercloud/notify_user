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

      describe 'push options' do
        it 'sets the mobile message' do
          expect(@apns.push_options[:alert]).to eq "New Post Notification happened with {}"
        end

        it 'sets the badge to 1' do
          expect(@apns.push_options[:badge]).to eq 1
        end

        it 'sets the notification category' do
          expect(@apns.push_options[:category]).to eq "NewPostNotification"
        end

        it 'sets the custom data with params' do
          expect(@apns.push_options[:custom_data]).to eq notification.sendable_params
        end

        it 'has a default sound' do
          expect(@apns.push_options[:sound]).to eq 'default'
        end

        it 'can use custom sounds' do
          apns = Apns.new([notification], [], sound: 'special.wav')

          expect(apns.push_options[:sound]).to eq 'special.wav'
        end

        it 'removes the badge key for silent notifications' do
          apns = Apns.new([notification], [], silent: true)

          expect(apns.push_options).not_to have_key(:badge)
        end
      end
    end

    describe 'push' do
      before :each do
        @apns = Apns.new([notification], [], {})

        @connection = TestAPNConnection.new

        allow(@apns).to receive(:connection)   { @connection }
      end

      context 'with no errors' do
        before :each do
          allow(IO).to receive(:select) { [nil, nil] }
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
          expect(@connection).to receive(:write).exactly(3).times
          @apns.push
        end
      end

      context 'with an error' do
        before :each do
          # Return errors first time, no errors on recursion
          allow(IO).to receive(:select).and_return([[true], nil], [nil, nil])
          error_string = "nil, #{status}, #{error_index}"
          allow(@connection).to receive(:read) { error_string }
        end

        let(:status) { 8 }
        let(:error_index) { 0 }

        it 'tries again if an error occurs' do
          expect(@apns).to receive(:send_notifications).twice.and_call_original
          @apns.push
        end
      end
    end
  end
end
