require 'spec_helper'

module NotifyUser
  describe BaseNotification do

    let(:user) { User.create({email: "user@example.com" })}
    let(:notification) { NewPostNotification.create({target: user}) }
    Rails.application.routes.default_url_options[:host]= 'localhost:5000' 

    before :each do
      BaseNotification.any_instance.stub(:mobile_message).and_return("New Notification")
    end

    describe "#notify" do

      it "raises an exception if the notification is not valid" do
        notification.target = nil
        expect { notification.notify }.to raise_error
      end

      it "doesn't send if unsubscribed from channel" do
        unsubscribe = NotifyUser::Unsubscribe.create({target: user, type: "NewPostNotification"}) 
        ActionMailerChannel.should_not_receive(:deliver)
        BaseNotification.deliver_notification_channel(notification.id, "action_mailer")
      end

      it "does send if subscribed to channel" do
        ActionMailerChannel.should_receive(:deliver)
        BaseNotification.deliver_notification_channel(notification.id, "action_mailer")
      end

      describe "with aggregation enabled" do

        it "schedules a job to wait for more notifications to aggregate if there is not one already" do
          BaseNotification.should_receive(:delay_for)
                          .with(notification.class.aggregate_per)
                          .and_call_original
          ActionMailerChannel.should_receive(:deliver)
          Apns.should_receive(:push_notification)
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

          it "sends an aggregated email if more than one notification queued up" do
            Sidekiq::Testing.inline!
            
            NewPostNotification.create({target: user})

            NotificationMailer.should_receive(:aggregate_notifications_email).with(BaseNotification.pending_aggregation_with(notification), anything).and_call_original
            BaseNotification.notify_aggregated(notification.id)
          end

          it "sends a singular email if no more notifications were queued since the original was delayed" do
            Sidekiq::Testing.inline!
            Apns.should_receive(:push_notification)
            NotificationMailer.should_receive(:notification_email).with(notification, anything).and_call_original
            BaseNotification.notify_aggregated(notification.id)

          end

        end
      end

    end

    describe "#notify!" do

      it "sends immediately, ignoring aggregation" do
        Apns.should_receive(:push_notification)
        BaseNotification.should_not_receive(:delay_for)
        ActionMailerChannel.should_receive(:deliver)
        notification.notify!
      end

      it "doesn't send if unsubscribed from type" do
        unsubscribe = NotifyUser::Unsubscribe.create({target: user, type: "NewPostNotification"}) 
        ActionMailerChannel.should_not_receive(:deliver)
        ApnsChannel.should_not_receive(:deliver)

        notification.notify!

      end

      it "doesn't send if unsubscribed from mailer channel" do
        unsubscribe = NotifyUser::Unsubscribe.create({target: user, type: "action_mailer"}) 
        ActionMailerChannel.should_not_receive(:deliver)
        ApnsChannel.should_receive(:deliver)
        notification.notify!
      end

    end

    describe "generate hash" do
      it "creates a new hash if an active hash doesn't already exist" do
        user_hash = notification.generate_unsubscribe_hash
        user_hash.should_not eq nil
      end

      it "uses the old hash if an active hash already exists" do
        user_hash = notification.generate_unsubscribe_hash

        another_hash = notification.generate_unsubscribe_hash
        another_hash.token.should eq user_hash.token
      end

      it "creates a new hash if no active hash exists" do
        user_hash = notification.generate_unsubscribe_hash
        user_hash.deactivate

        another_hash = notification.generate_unsubscribe_hash
        another_hash.token.should_not eq user_hash.token

      end
    end
  end
end
