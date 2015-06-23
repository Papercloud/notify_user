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

      describe "#deliver" do

        describe "with aggregation enabled" do
          it "schedules a job to wait for more notifications to aggregate if there is not one already" do
            NewPostNotification.should_receive(:delay_for)
                            .with(notification.class.aggregate_per).and_call_original

            notification.deliver
          end

          it "doesn't schedule a job if a pending notification awaiting aggregation already exists" do
            another_notification = NewPostNotification.create({target: user, state: "pending_as_aggregation_parent"})
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

      it "if notification is marked_as_read don't deliver" do
        notification = NewPostNotification.create({target: user, state: "read"})

        NewPostNotification.should_not_receive(:deliver_notification_channel)
        NewPostNotification.should_not_receive(:deliver_notifications_channel)

        NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
      end

      describe "aggregate_grouping enabled" do
        before :each do
          NewPostNotification.class_eval do
            channel :action_mailer, aggregate_grouping: true
          end
        end

        it "should receive pending_aggregation_by_group_with" do
          notification = NewPostNotification.create({target: user, params: {group_id: 1}})
          NewPostNotification.should_receive(:pending_aggregation_by_group_with).and_call_original

          NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
        end
      end

    end

    describe "interval aggregation" do
      before :each do
        Sidekiq::Testing.fake!
        @aggregate_per = [0, 1, 4, 5]
        NewPostNotification.class_eval do
          channel :action_mailer, aggrregate_per: @aggregate_per, aggregate_grouping: true
        end
      end

      it "marking a pending_as_aggregation_parent as sent sets it to sent_as_aggregation_parent" do
        notification = NewPostNotification.create({target: user, params: {group_id: 1}, state: "pending_as_aggregation_parent"})
        notification.mark_as_sent!
        expect(notification.reload.state).to eq "sent_as_aggregation_parent"
      end

      describe "aggregate interval" do
        describe "first notification to be received after a notification was sent" do
          it "first notification returns interval 0" do
            notification = NewPostNotification.create({target: user, params: {group_id: 1}})
            expect(notification.aggregation_interval).to eq 0
          end

          it "second notification returns internal 1" do
            NewPostNotification.create({target: user, params: {group_id: 1}, state: "sent_as_aggregation_parent"})
            notification = NewPostNotification.create({target: user, params: {group_id: 1}})
            expect(notification.aggregation_interval).to eq 1
          end

          it "third notification returns interval 2" do
            NewPostNotification.create({target: user, params: {group_id: 1}, state: "sent_as_aggregation_parent"})
            NewPostNotification.create({target: user, params: {group_id: 1}, state: "sent_as_aggregation_parent"})

            notification = NewPostNotification.create({target: user, params: {group_id: 1}})
            expect(notification.aggregation_interval).to eq 2
          end

          it "doesn't include sent notifications from another target_id" do
            NewPostNotification.create({target: user, params: {group_id: 3}, state: "sent_as_aggregation_parent"})
            NewPostNotification.create({target: user, params: {group_id: 0}, state: "sent_as_aggregation_parent"})

            notification = NewPostNotification.create({target: user, params: {group_id: 1}})
            expect(notification.aggregation_interval).to eq 0
          end
        end
      end

      describe "delay_time" do

        it "first notification will return Time.now" do
          notification = NewPostNotification.create({target: user, params: {group_id: 1}})
          expect(notification.delay_time({aggregate_per: @aggregate_per})).to eq notification.created_at
        end

        it "notification received during first interval returns last time + x.minutes " do
          n = NewPostNotification.create!({target: user, params: {group_id: 1}, state: "pending_as_aggregation_parent"})
          n.mark_as_sent!

          notification = NewPostNotification.create!({target: user, params: {group_id: 1}})
          expect(notification.delay_time({aggregate_per: @aggregate_per})).to eq n.sent_time + 1.minute
        end

        it "notification returned during third interval returns last time + x.minutes" do
          NewPostNotification.create({target: user, params: {group_id: 1}, state: "pending_as_aggregation_parent"}).mark_as_sent!
          n = NewPostNotification.create({target: user, params: {group_id: 1}, state: "pending_as_aggregation_parent"})
          n.mark_as_sent!

          notification = NewPostNotification.create({target: user, params: {group_id: 1}})
          expect(notification.delay_time({aggregate_per: @aggregate_per})).to eq n.sent_time + 4.minute
        end

        it "notification received after all intervals have ended just uses the last interval" do
          10.times do
            NewPostNotification.create({target: user, params: {group_id: 1}, state: "pending_as_aggregation_parent"}).mark_as_sent!
          end
          last_n = NewPostNotification.create({target: user, params: {group_id: 1}, state: "pending_as_aggregation_parent"})
          last_n.mark_as_sent!

          notification = NewPostNotification.create({target: user, params: {group_id: 1}})
          expect(notification.delay_time({aggregate_per: @aggregate_per})).to eq last_n.sent_time + 5.minute
        end
      end

      describe "the first notification" do
        before :each do
          @notification = NewPostNotification.create({target: user, params: {group_id: 1}})
        end

        it "should send immediately" do
          expect{
            @notification.deliver
          }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(1)
        end

        it "should change state to pending_as_aggregation_parent" do
          expect{
            @notification.deliver
          }.to change(@notification, :state).to "pending_as_aggregation_parent"
        end
      end

      describe "receive subsequent notifications" do

        describe "with no pending notifications" do
          it "delays notification" do
            n = NewPostNotification.create({target: user, params: {group_id: 1}, state: "sent_as_aggregation_parent"})
            notification = NewPostNotification.create({target: user, params: {group_id: 1}, created_at: n.created_at + 2.minutes})

            expect{
              notification.deliver
            }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(1)
          end

        end

        describe "with pending notifications" do
          before :each do
            @other_notification = NewPostNotification.create({target: user, state: "pending_as_aggregation_parent", params: {group_id: 1}})
            @notification = NewPostNotification.create({target: user, params: {group_id: 1}})
          end

          it "dont delay anything" do
            expect{
              @notification.deliver
            }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(0)
          end

          it "state remains as pending" do
            @notification.deliver
            expect(@notification.reload.pending?).to eq true
          end
        end
      end
      #we need a way to identify which notification was the one that was delayed conceptually labeled "head" or a special state
      #search how many unread/sent "head" notifications exist and use that as the interval
    end

    describe "validations" do
      describe "aggregate_grouping false" do
        before :each do
          NewPostNotification.class_eval do
            channel :action_mailer, aggrregate_per: [1, 4, 5]
          end
        end

        it "doesn't require a params_target_id" do
          notification = NewPostNotification.new({target: user})
          expect(notification).to be_valid
        end
      end

      describe "aggregate_grouping true" do
        before :each do
          NewPostNotification.class_eval do
            channel :action_mailer, aggrregate_per: [1, 4, 5], aggregate_grouping: true
          end
        end

        it "if group_id present be valid" do
          notification = NewPostNotification.new({target: user, params: {group_id: 0}})
          expect(notification).to be_valid
        end
        it "if aggregate_grouping is true require a params_group_id" do
          notification = NewPostNotification.new({target: user})
          expect(notification).to_not be_valid
        end
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
