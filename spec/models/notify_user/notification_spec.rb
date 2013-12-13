require 'spec_helper'

module NotifyUser
  describe BaseNotification do

    let(:user) { User.create({email: "user@example.com" })}
    let(:notification) { NewPostNotification.create({target: user}) }

    describe "#notify" do

      it "raises an exception if the notification is not valid" do
        notification.target = nil
        expect { notification.notify }.to raise_error
      end

      describe "with aggregation enabled" do

        it "schedules a job to wait for more notifications to aggregate if there is not one already" do
          BaseNotification.should_receive(:delay_for)
                          .with(notification.class.aggregate_per)
                          .and_call_original
          notification.notify
        end

        it "does not schedule an aggregation job if there is one already" do
          Sidekiq::Testing.fake!

          notification.notify
          
          another_notification = NewPostNotification.new({target: user})

          BaseNotification.should_not_receive(:delay_for)
          another_notification.notify
        end

        describe ".notify_aggregated" do

          it "sends an aggregated email" do
            Sidekiq::Testing.inline!
            
            NotificationMailer.should_receive(:aggregate_notifications_email).with([notification.id])
            BaseNotification.notify_aggregated(notification.id)
          end

        end
      end

    end

  end
end
