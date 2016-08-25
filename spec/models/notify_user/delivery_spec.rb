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
        delivery = build(:delivery, deliver_in: 0, notification: @notification, channel: 'apns')

        TestAfterCommit.with_commits(true) do
          expect(NotifyUser::DeliveryWorker).to receive(:perform_in).with(0.seconds)
          delivery.save
        end
      end
    end
  end
end
