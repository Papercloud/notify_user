require 'spec_helper'

module NotifyUser
  describe Scheduler do
    before :each do
      @user = create(:user)
    end

    describe '#schedule' do
      context 'one channel' do
        before :each do
          allow(NewPostNotification).to receive(:channels) {{
              apns: { aggregate_per: [0, 3, 10, 30, 60] }
          }}
        end

        subject do
          create_notification_for_user(@user, {})
        end

        context 'with pending deliveries' do
          before :each do
            allow_any_instance_of(Aggregator).to receive(:has_pending_deliveries?) { true }
          end

          it 'creates no delivery object' do
            expect do
              described_class.schedule(subject)
            end.not_to change(Delivery, :count)
          end
        end

        context 'without pending deliveries' do
          it 'creates a delivery object' do
            expect do
              described_class.schedule(subject)
            end.to change(Delivery, :count).by(1)
          end

          it 'sets the seconds to wait for delivering on the delivery' do
            create_notification_for_user(@user, { })
            create_notification_for_user(@user, { })

            described_class.schedule(subject)
            expect(subject.reload.deliveries.last.deliver_in).to eq 600
          end

          it 'sets the delay time to 0 if the proposed send time is in the past' do
            Timecop.freeze(Time.zone.now - 12.hours) do
              create_notification_for_user(@user, { })
              create_notification_for_user(@user, { })
            end

            described_class.schedule(subject)
            expect(subject.reload.deliveries.last.deliver_in).to eq 0
          end

          it 'sets the channel of the delivery' do
            described_class.schedule(subject)
            expect(subject.reload.deliveries.last.channel).to eq 'apns'
          end
        end
      end

      context 'multiple channels' do
        before :each do
          allow(NewPostNotification).to receive(:channels) {{
              apns: { aggregate_per: [0, 3, 10, 30, 60] },
              gcm: { aggregate_per: [0, 3, 10, 30, 60] }
          }}
        end

        subject do
          create_notification_for_user(@user, {})
        end

        it 'creates a delivery object per channel' do
          expect do
            described_class.schedule(subject)
          end.to change(Delivery, :count).by(2)
        end
      end
    end

    def create_notification_for_user(user, options = {})
      NewPostNotification.create({ target: user }.merge(options))
    end
  end
end
