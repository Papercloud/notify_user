require 'spec_helper'

module NotifyUser
  describe BaseNotification do

    let(:user) { User.create({email: "user@example.com" })}
    let(:notification) { NewPostNotification.create({target: user}) }
    Rails.application.routes.default_url_options[:host]= 'localhost:5000'

    before :each do
      BaseNotification.any_instance.stub(:mobile_message).and_return("New Notification")
      # BaseNotification.channel(:apns, {aggregate_per: false})
    end

    describe "notification count" do
      it "returns the sent count for a user" do
        notification.count_for_target.should eq 1
      end
    end

    describe "params" do

      it "doesn't fail if searching for param variable that doesn't exist" do
        notification.params[:unknown].should eq nil
      end

      it "doesn't fail if searching for a param that doesn't exist if other params are present" do
        notification.params = {name: "hello_world"}
        notification.params[:unknown].should eq nil
      end

      it "can reference params using string when submitted as json" do
        notification.params = {"listing_id" => 1}
        notification.save

        NewPostNotification.last.params["listing_id"].should eq 1
      end

      it "can reference params using symbol when submitted as json" do
        notification.params = {"listing_id" => 1}
        notification.save

        NewPostNotification.last.params[:listing_id].should eq 1
      end

      it "can reference params using symbol when submitted as hash" do
        notification.params = {:listing_id => 1}
        notification.save

        NewPostNotification.last.params[:listing_id].should eq 1
      end

      it "can reference params using string when subbmited as hash" do
        notification.params = {:listing_id => 1}
        notification.save

        NewPostNotification.last.params["listing_id"].should eq 1
      end
    end

    describe "#notify" do

      it "sets the state to pending" do
        notification = NewPostNotification.create({target: user})
        notification.notify
        notification.state.should eq "pending"
      end

      it "notify(false) marks the notification as sent" do
        notification = NewPostNotification.create({target: user})
        notification.notify(false)
        notification.state.should eq "sent"
      end

      describe "#deliver" do

        describe "with aggregation enabled" do
          it "schedules a job to wait for more notifications to aggregate if there is not one already" do
            NewPostNotification.should_receive(:delay_for)
                            .with(notification.class.aggregate_per).and_call_original

            notification.deliver
          end

          it "doesn't schedule a job if a pending notification awaiting aggregation already exists" do
            another_notification = NewPostNotification.create({target: user})
            NewPostNotification.should_not_receive(:delay_for)
                            .with(notification.class.aggregate_per).and_call_original

            notification.deliver
          end
        end

        describe "with aggregation disabled" do
          before :each do
            NewPostNotification.channel(:action_mailer, {aggregate_per: false})
          end

          it "schedules notification to be sent through channels" do
            NewPostNotification.should_receive(:delay).and_call_original
            notification.deliver
          end
        end
      end
    end

    describe "notify!" do

      it "sets the state to pending_no_aggregation" do
        notification = NewPostNotification.create({target: user})
        notification.notify!
        notification.state.should eq "pending_no_aggregation"
      end

      describe ".deliver_notification_channel" do

          before :each do
            @notification = NewPostNotification.create({target: user})
          end

          it "doesn't send if unsubscribed from channel" do
            unsubscribe = NotifyUser::Unsubscribe.create({target: user, type: "action_mailer"})
            ActionMailerChannel.should_not_receive(:deliver)
            BaseNotification.deliver_notification_channel(@notification.id, "action_mailer")
          end

          it "does send if subscribed to channel" do
            ActionMailerChannel.should_receive(:deliver)
            BaseNotification.deliver_notification_channel(@notification.id, "action_mailer")
          end
      end

      describe "#deliver!" do
        it "schedules to be delivered to channels" do
          notification.dont_aggregate
          NewPostNotification.should_receive(:deliver_channels)
                              .with(notification.id)
                              .and_call_original
          notification.deliver!
        end
      end

      describe "#deliver_channels" do

        it "delivers notification to channels" do
          ActionMailerChannel.should_receive(:deliver).once
          NewPostNotification.deliver_channels(notification.id)
        end

      end
    end

    describe "#notify_aggregated_channel"  do

      it "if only one notification to aggregate hit deliver_notification_channel" do
        NewPostNotification.should_receive(:deliver_notification_channel).with(notification.id, :action_mailer).once
        NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
      end

      it "if many notifications to aggregate hit deliver_notifications_channel" do
        another_notification = NewPostNotification.create({target: user})

        NewPostNotification.should_receive(:deliver_notifications_channel).once
        NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
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
