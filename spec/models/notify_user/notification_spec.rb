require 'spec_helper'

module NotifyUser
  describe BaseNotification do

    let(:user) { User.create({email: "user@example.com" })}
    let(:notification) { NewPostNotification.create({target: user}) }
    Rails.application.routes.default_url_options[:host]= 'localhost:5000'

    before :each do
      NewPostNotification.class_eval do
        channel :action_mailer
        self.aggregate_grouping = false
      end

      allow_any_instance_of(BaseNotification).to receive(:mobile_message) { 'New Notification' }
    end

    describe "notification count" do
      it "returns the sent count for a user" do
        expect(notification.count_for_target).to eq 1
      end
    end

    describe "params" do
      it "doesn't fail if searching for param variable that doesn't exist" do
        expect(notification.params[:unknown]).to eq nil
      end

      it "doesn't fail if searching for a param that doesn't exist if other params are present" do
        notification.params = {name: "hello_world"}
        expect(notification.params[:unknown]).to eq nil
      end

      it "can reference params using string when submitted as json" do
        notification.params = {"listing_id" => 1}
        notification.save

        expect(NewPostNotification.last.params["listing_id"]).to eq 1
      end

      it "can reference params using symbol when submitted as json" do
        notification.params = {"listing_id" => 1}
        notification.save

        expect(NewPostNotification.last.params[:listing_id]).to eq 1
      end

      it "can reference params using symbol when submitted as hash" do
        notification.params = {:listing_id => 1}
        notification.save

        expect(NewPostNotification.last.params[:listing_id]).to eq 1
      end

      it "can reference params using string when subbmited as hash" do
        notification.params = {:listing_id => 1}
        notification.save

        expect(NewPostNotification.last.params["listing_id"]).to eq 1
      end
    end

    describe "#notify" do
      before do
        @notification = NewPostNotification.create(target: user)
      end

      it "sets the state to pending" do
        @notification.notify
        expect(@notification.reload.state).to eq 'pending'
      end

      it "passing false marks the notification as sent" do
        @notification.notify(false)
        expect(@notification.reload.state).to eq 'sent'
      end

      context 'using aggregation' do
        before do
          allow(NewPostNotification).to receive(:aggregate_grouping) { true }
        end

        it 'doesnt assign a parent if there arent any' do
          @notification.notify
          expect(@notification.reload.parent_id).to be_nil
        end

        it 'doesnt assign a parent if one hasnt been created within 24 hours' do
          @t = 25.hours.ago
          @parent = NewPostNotification.create(target: user, created_at: @t)

          @notification.notify
          expect(@notification.reload.parent_id).to be_nil
        end

        it 'assigns a parent if one has been created within 24 hours' do
          @t = 23.hours.ago
          @parent = NewPostNotification.create(target: user, created_at: @t)

          @notification.notify
          expect(@notification.reload.parent_id).to eq @parent.id
        end
      end
    end

    describe "#deliver" do
      context "with aggregation enabled" do
        it "schedules a job to wait for more notifications to aggregate if there is not one already" do
          expect { notification.deliver }.to change { Que.job_stats.length }.from(0).to(1)
        end

        it "doesn't schedule a job if a pending notification awaiting aggregation already exists" do
          expect { notification.deliver }.to change { Que.job_stats.length }.from(0).to(1)
        end
      end

      context "with aggregation disabled" do
        before :each do
          NewPostNotification.channel(:action_mailer, {aggregate_per: false})
        end

        it "schedules notification to be sent through channels" do
          expect { notification.deliver }.to change { Que.job_stats.length }.from(0).to(1)
        end
      end
    end

    describe "notify!" do
      it "sets the state to pending_no_aggregation" do
        notification = NewPostNotification.create({target: user})
        notification.notify!

        expect(notification.state).to eq "pending_no_aggregation"
      end

      describe ".deliver_notification_channel" do
        before :each do
          @notification = NewPostNotification.create({target: user})
        end

        it "doesn't send if unsubscribed from channel" do
          NotifyUser::Unsubscribe.create({target: user, type: "action_mailer"})

          expect(ActionMailerChannel).not_to receive(:deliver)
          BaseNotification.deliver_notification_channel(@notification.id, "action_mailer")
        end

        it "does send if subscribed to channel" do
          expect(ActionMailerChannel).to receive(:deliver)
          BaseNotification.deliver_notification_channel(@notification.id, "action_mailer")
        end
      end

      describe "#deliver!" do
        it "schedules to be delivered to channels" do
          notification.dont_aggregate

          expect(NewPostNotification).to(
            receive(:deliver_channels).with(notification.id)
          ).and_call_original

          notification.deliver!
        end
      end

      describe "#deliver_channels" do
        it "delivers notification to channels" do
          expect(ActionMailerChannel).to receive(:deliver).once
          NewPostNotification.deliver_channels(notification.id)
        end
      end
    end

    describe "#notify_aggregated_channel"  do
      it "if only one notification to aggregate hit deliver_notification_channel" do
        expect(NewPostNotification).to receive(:deliver_notification_channel).with(notification.id, :action_mailer).once
        NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
      end

      it "if many notifications to aggregate hit deliver_notifications_channel" do
        another_notification = NewPostNotification.create({target: user})

        expect(NewPostNotification).to receive(:deliver_notifications_channel).once
        NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
      end

      it "if notification is marked_as_read don't deliver" do
        notification = NewPostNotification.create({target: user, state: "read"})

        expect(NewPostNotification).not_to receive(:deliver_notification_channel)
        expect(NewPostNotification).not_to receive(:deliver_notifications_channel)

        NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
      end

      context "with aggregate grouping enabled" do
        before do
          allow(NewPostNotification).to receive(:aggregate_grouping) { true }
        end

        it "should receive pending_aggregation_by_group_with" do
          notification = NewPostNotification.create({target: user, group_id: 2})

          expect(NewPostNotification).to receive(:pending_aggregation_by_group_with).and_call_original
          NewPostNotification.notify_aggregated_channel(notification.id, :action_mailer)
        end
      end
    end

    describe "interval aggregation" do
      before :each do
        Sidekiq::Testing.fake!
        @aggregate_per = [0, 1, 4, 5]
        NewPostNotification.class_eval do
          channel :action_mailer, aggrregate_per: @aggregate_per

          self.aggregate_grouping = true
        end
      end

      it "marking a pending_as_aggregation_parent as sent sets it to sent_as_aggregation_parent" do
        notification = NewPostNotification.create({target: user, group_id: 1, state: "pending_as_aggregation_parent"})
        notification.mark_as_sent!
        expect(notification.reload.state).to eq "sent_as_aggregation_parent"
      end

      describe "aggregate interval" do
        describe "first notification to be received after a notification was sent" do
          it "includes notifications within 24hours from first notification" do
          end

          it "first notification returns interval 0" do
            notification = NewPostNotification.create({target: user, group_id: 1})
            expect(notification.aggregation_interval).to eq 0
          end

          it "second notification returns internal 1" do
            NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent"})
            notification = NewPostNotification.create({target: user, group_id: 1})
            expect(notification.aggregation_interval).to eq 1
          end

          it "third notification returns interval 2" do
            NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent"})
            NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent"})

            notification = NewPostNotification.create({target: user, group_id: 1})
            expect(notification.aggregation_interval).to eq 2
          end

          it "doesn't include sent notifications from another target_id" do
            NewPostNotification.create({target: user, group_id: 3, state: "sent_as_aggregation_parent"})
            NewPostNotification.create({target: user, group_id: 0, state: "sent_as_aggregation_parent"})

            notification = NewPostNotification.create({target: user, group_id: 1})
            expect(notification.aggregation_interval).to eq 0
          end

          it "agregation interval should include pending as parent states as well" do
            NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent"})
            NewPostNotification.create({target: user, group_id: 1, state: "pending_as_aggregation_parent"})

            notification = NewPostNotification.create({target: user, group_id: 1})
            expect(notification.aggregation_interval).to eq 2
          end
        end
      end

      describe "parent_id" do
        it "sets parent_id if the time between the previous parent_id is less than 24 hours ago" do
          n = NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent", parent_id: nil})

          Timecop.travel(10.hours.from_now) do
            notification = NewPostNotification.new({target: user, group_id: 1})
            notification.notify

            expect(notification.parent_id).to eq n.id
          end
        end

        it "does not set parent_id if time between previous parent_id is more than 24 hours ago" do
          n = NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent", parent_id: nil})

          Timecop.travel(25.hours.from_now) do
            notification = NewPostNotification.new({target: user, group_id: 1})
            notification.notify

            expect(notification.reload.parent_id).to eq nil
          end
        end

        it "parent_id gets set to the latest id of the latest parents" do
          NewPostNotification.create({target: user, group_id: 1, parent_id: nil})

          Timecop.travel(10.hours.from_now) do
            n = NewPostNotification.new({target: user, group_id: 1, parent_id: nil, created_at: 10.hours.ago})

            Timecop.travel(15.hours.from_now) do
              notification = NewPostNotification.new({target: user, group_id: 1})
              notification.notify

              expect(notification.reload.parent_id).to eq n.id
            end
          end
        end
      end

      describe "delay_time" do

        it "first notification will return Time.now" do
          notification = NewPostNotification.create({target: user, group_id: 1})
          expect(notification.delay_time({aggregate_per: @aggregate_per}).to_s).to eq notification.created_at.to_s
        end

        it "notification received during first interval returns last time + x.minutes " do
          n = NewPostNotification.create!({target: user, group_id: 1, state: "pending_as_aggregation_parent"})
          n.mark_as_sent!

          notification = NewPostNotification.create!({target: user, group_id: 1})
          expect(notification.delay_time({aggregate_per: @aggregate_per}).to_s).to eq (n.sent_time + 1.minute).to_s
        end

        it "notification returned during third interval returns last time + x.minutes" do
          NewPostNotification.create({target: user, group_id: 1, state: "pending_as_aggregation_parent"}).mark_as_sent!
          n = NewPostNotification.create({target: user, group_id: 1, state: "pending_as_aggregation_parent"})
          n.mark_as_sent!

          notification = NewPostNotification.create({target: user, group_id: 1})
          expect(notification.delay_time({aggregate_per: @aggregate_per}).to_s).to eq (n.sent_time + 4.minute).to_s
        end

        it "notification received after all intervals have ended just uses the last interval" do
          10.times do
            NewPostNotification.create({target: user, group_id: 1, state: "pending_as_aggregation_parent"}).mark_as_sent!
          end
          last_n = NewPostNotification.create({target: user, group_id: 1, state: "pending_as_aggregation_parent"})
          last_n.mark_as_sent!

          notification = NewPostNotification.create({target: user, group_id: 1})
          expect(notification.delay_time({aggregate_per: @aggregate_per}).to_s).to eq (last_n.sent_time + 5.minute).to_s
        end
      end

      describe "the first notification" do
        before :each do
          @notification = NewPostNotification.create({target: user, group_id: 1})
        end

        it "should send immediately" do
          expect { @notification.deliver }.to change { Que.job_stats.length }.from(0).to(1)
        end

        it "should change state to pending_as_aggregation_parent" do
          expect{
            @notification.deliver
          }.to change(@notification, :state).to "pending_as_aggregation_parent"
        end

        it "parent_id should be nil" do
          @notification.deliver
          expect(@notification.reload.parent_id).to eq nil
        end
      end

      describe "receive subsequent notifications" do

        describe "with no pending notifications" do
          before :each do
            @n = NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent"})
          end

          it "delays notification" do
            notification = NewPostNotification.create({target: user, group_id: 1, created_at: @n.created_at + 2.minutes})

            expect { notification.deliver }.to change { Que.job_stats.length }.from(0).to(1)
          end

          it "parent_id gets set to notification at interval 0" do
            notification = NewPostNotification.new({target: user, group_id: 1, created_at: @n.created_at + 2.minutes})
            notification.notify
            expect(notification.reload.parent_id).to eq @n.id
          end

        end

        describe "with pending notifications" do
          before :each do
            @n = NewPostNotification.create({target: user, group_id: 1, state: "sent_as_aggregation_parent"})
            @other_notification = NewPostNotification.create({target: user, state: "pending_as_aggregation_parent", group_id: 1})
            @notification = NewPostNotification.create({target: user, group_id: 1})
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

        it "doesn't require a group_id" do
          notification = NewPostNotification.new({target: user})
          expect(notification).to be_valid
        end
      end

      describe "aggregate_grouping true" do
        before :each do
          NewPostNotification.class_eval do
            channel :action_mailer, aggrregate_per: [1, 4, 5]
            self.aggregate_grouping = true
          end
        end

        it "if group_id present be valid" do
          notification = NewPostNotification.new({target: user, group_id: 1})
          expect(notification).to be_valid
        end
        it "if aggregate_grouping is true require a group_id" do
          notification = NewPostNotification.new({target: user})
          expect(notification).to_not be_valid
        end
      end
    end

    describe "user_has_unsubscribed?" do
      it "true if unsubscribed from type" do
        notification = NewPostNotification.create({target: user})
        Unsubscribe.create({target: notification.target, type: "NewPostNotification"})

        expect(notification.user_has_unsubscribed?).to eq true
      end

      it "false if haven't unsubscribed from type" do
        notification = NewPostNotification.create({target: user})
        expect(notification.user_has_unsubscribed?).to eq false
      end

      it "true if unsubscribed from channel" do
        notification = NewPostNotification.create({target: user})
        Unsubscribe.create({target: notification.target, type: "action_mailer"})

        expect(notification.user_has_unsubscribed?(:action_mailer)).to eq true
      end

      it "false if haven't unsubscribed from channel" do
        notification = NewPostNotification.create({target: user})

        expect(notification.user_has_unsubscribed?(:action_mailer)).to eq false
      end

      it "true if unsubscribed from type and group_id" do
        Unsubscribe.create({target: notification.target, type: "NewPostNotification", group_id: 1})
        notification.update_attributes(group_id: 1)

        expect(notification.user_has_unsubscribed?).to eq true
      end

      it "true if unsubcribed from type but pass in group_id" do
        Unsubscribe.create({target: notification.target, type: "NewPostNotification"})
        notification.update_attributes(group_id: 1)

        expect(notification.user_has_unsubscribed?).to eq true
      end

      it "false if havent unsubscribed from type and group_id" do
        notification.update_attributes(group_id: 1)
        expect(notification.user_has_unsubscribed?).to eq false
      end
    end

    describe "unsubscribing" do

      describe "deliver_notification_channel" do
        it "subscribed to type receives deliver" do
          expect(ActionMailerChannel).to receive(:deliver)
          NewPostNotification.deliver_notification_channel(notification.id, :action_mailer)
        end

        it "unsubscribed from type doesn't receive deliver" do
          expect(ActionMailerChannel).to_not receive(:deliver)

          Unsubscribe.create({target: notification.target, type: "action_mailer"})
          NewPostNotification.deliver_notification_channel(notification.id, :action_mailer)
        end

        it "unsubscribed from type and group_id doesn't receive deliver " do
          expect(ActionMailerChannel).to_not receive(:deliver)
          Unsubscribe.create({target: notification.target, type: "NewPostNotification", group_id: 1})

          notification.update_attributes(group_id: 1)

          NewPostNotification.deliver_notification_channel(notification.id, :action_mailer)
        end

      end

      describe "deliver_notifications_channel" do

        it "subscribed to type receives deliver_aggregated" do
          expect(ActionMailerChannel).to receive(:deliver_aggregated)
          NewPostNotification.deliver_notifications_channel([notification], :action_mailer)
        end

        it "unsubscribed from type doesn't receive deliver_aggregated" do
          expect(ActionMailerChannel).to_not receive(:deliver_aggregated)

          Unsubscribe.create({target: notification.target, type: "action_mailer"})
          NewPostNotification.deliver_notifications_channel([notification], :action_mailer)
        end

        it "unsubscribed from type and group_id doesn't receive deliver_aggregated " do
          expect(ActionMailerChannel).to_not receive(:deliver_aggregated)

          Unsubscribe.create({target: notification.target, type: "NewPostNotification", group_id: 1})
          notification.update_attributes(group_id: 1)

          NewPostNotification.deliver_notifications_channel([notification], :action_mailer)
        end
      end
    end

    describe "generate hash" do
      it "creates a new hash if an active hash doesn't already exist" do
        user_hash = notification.generate_unsubscribe_hash
        expect(user_hash).not_to eq nil
      end

      it "uses the old hash if an active hash already exists" do
        user_hash = notification.generate_unsubscribe_hash

        another_hash = notification.generate_unsubscribe_hash
        expect(another_hash.token).to eq user_hash.token
      end

      it "creates a new hash if no active hash exists" do
        user_hash = notification.generate_unsubscribe_hash
        user_hash.deactivate

        another_hash = notification.generate_unsubscribe_hash
        expect(another_hash.token).not_to eq user_hash.token
      end
    end
  end
end
