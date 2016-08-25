require 'spec_helper'

module NotifyUser
  describe BaseNotification do
    class TestNotification < BaseNotification; end

    describe "validations" do
      context "aggregate_grouping false" do
        before :each do
          allow(NewPostNotification).to receive(:aggregate_grouping) { false }
        end

        it "doesn't require a group_id" do
          notification = build(:notify_user_notification, group_id: nil)
          expect(notification).to be_valid
        end
      end

      context "aggregate_grouping true" do
        before :each do
          allow(NewPostNotification).to receive(:aggregate_grouping) { true }
        end

        it "if group_id present be valid" do
          notification = build(:notify_user_notification, group_id: nil)
          expect(notification).not_to be_valid
        end
      end
    end

    describe "#params" do
      it "doesn't fail if searching for param variable that doesn't exist" do
        notification = build(:notify_user_notification)
        expect(notification.params[:unknown]).to eq nil
      end

      it "doesn't fail if searching for a param that doesn't exist if other params are present" do
        notification = build(:notify_user_notification, params: { name: "hello_world" })
        expect(notification.params[:unknown]).to eq nil
      end

      it "can reference params using string when submitted as json" do
        notification = create(:notify_user_notification, params: { "listing_id" => 1 }).reload
        expect(notification.params["listing_id"]).to eq 1
      end

      it "can reference params using symbol when submitted as json" do
        notification = create(:notify_user_notification, params: { "listing_id" => 1 }).reload
        expect(notification.params[:listing_id]).to eq 1
      end

      it "can reference params using symbol when submitted as hash" do
        notification = create(:notify_user_notification, params: { listing_id: 1 }).reload
        expect(notification.params[:listing_id]).to eq 1
      end

      it "can reference params using string when subbmited as hash" do
        notification = create(:notify_user_notification, params: { listing_id: 1 }).reload
        expect(notification.params["listing_id"]).to eq 1
      end
    end

    describe "#to" do
      let(:user) { create(:user) }

      it 'sets the target of the notification' do
        notification = build(:notify_user_notification)

        expect do
          notification.to(user)
        end.to change(notification, :target_id).to user.id
      end
    end

    describe "#with" do
      it 'sets the params of the notification' do
        notification = build(:notify_user_notification)

        expect do
          notification.with({ listing_id: 1 })
        end.to change(notification, :params).to({ listing_id: 1 })
      end
    end

    describe "#grouped_by_id" do
      it 'sets the grouping id of the notification' do
        notification = build(:notify_user_notification)

        expect do
          notification.grouped_by_id(1)
        end.to change(notification, :group_id).to(1)
      end
    end

    describe "#notify" do
      let(:user) { create(:user) }

      before :each do
        allow(NotifyUser::Scheduler).to receive(:schedule)
      end

      context 'with grouping' do
        before :each do
          allow(NewPostNotification).to receive(:aggregate_grouping) { true }
        end

        it 'sets no parent if this is the first notification of that group' do
          notification = build(:notify_user_notification, target: user, group_id: 1, params: {})

          expect do
            notification.notify
            notification.reload
          end.not_to change(notification, :parent_id).from(nil)
        end

        it 'sets a parent to the existing notification for the specified group' do
          old_notification = create(:notify_user_notification, target: user, group_id: 1, params: {})
          notification = build(:notify_user_notification, target: user, group_id: 1, params: {})

          expect do
            notification.notify
            notification.reload
          end.to change(notification, :parent_id).from(nil).to(old_notification.id)
        end

        it 'sets the parent to the last sent parent notification for the specified group' do
          older_notification = Timecop.freeze(Time.zone.now - 12.hours) do
             create(:notify_user_notification, target: user, group_id: 1, params: {})
          end

          old_notification = Timecop.freeze(Time.zone.now - 6.hours) do
             create(:notify_user_notification, target: user, group_id: 1, params: {})
          end

          notification = build(:notify_user_notification, target: user, group_id: 1, params: {})
          expect do
            notification.notify
            notification.reload
          end.to change(notification, :parent_id).from(nil).to(old_notification.id)
        end

        it 'sets no parent if the last sent parent notification is older than 24 hours' do
          older_notification = Timecop.freeze(Time.zone.now - 25.hours) do
             create(:notify_user_notification, target: user, group_id: 1, params: {})
          end

          notification = build(:notify_user_notification, target: user, group_id: 1, params: {})
          expect do
            notification.notify
            notification.reload
          end.not_to change(notification, :parent_id).from(nil)
        end
      end

      context 'without grouping' do
        before :each do
          allow(NewPostNotification).to receive(:aggregate_grouping) { false }
        end
      end

      context 'with delivery' do
        it 'runs the scheduler for delivery' do
          notification = create(:notify_user_notification, params: {})

          expect(NotifyUser::Scheduler).to receive(:schedule)
          notification.notify
        end
      end

      context 'without delivery' do
        it 'does not run the scheduler for delivery' do
          notification = create(:notify_user_notification, params: {})

          expect(NotifyUser::Scheduler).not_to receive(:schedule)
          notification.notify(false)
        end
      end
    end

    describe "#target_has_unsubscribed?" do
      let(:user) { create(:user) }

      it "returns true if target unsubscribed from type" do
        Unsubscribe.create({ target: user, type: NewPostNotification.name })

        notification = NewPostNotification.create({ target: user })
        expect(notification.target_has_unsubscribed?).to eq true
      end

      it "returns false if target hasn't unsubscribed from type" do
        notification = NewPostNotification.create({ target: user })
        expect(notification.target_has_unsubscribed?).to eq false
      end

      it "reutns true if target unsubscribed from channel" do
        Unsubscribe.create({ target: user, type: "action_mailer" })

        notification = NewPostNotification.create({ target: user })
        expect(notification.target_has_unsubscribed?(:action_mailer)).to eq true
      end

      it "returns false if target hasn't unsubscribed from channel" do
        notification = NewPostNotification.create({ target: user })
        expect(notification.target_has_unsubscribed?(:action_mailer)).to eq false
      end

      it "returns true if target unsubscribed from type and group_id" do
        Unsubscribe.create({ target: user, type: NewPostNotification.name, group_id: 1 })

        notification = NewPostNotification.create({ target: user, group_id: 1 })
        expect(notification.target_has_unsubscribed?).to eq true
      end

      it "returns true if target unsubcribed from type but pass in group_id" do
        Unsubscribe.create({target: user, type: NewPostNotification.name})

        notification = NewPostNotification.create({ target: user, group_id: 1 })
        expect(notification.target_has_unsubscribed?).to eq true
      end

      it "returns false if target hasn't unsubscribed from type and group_id" do
        notification = NewPostNotification.create({ target: user, group_id: 1 })
        expect(notification.target_has_unsubscribed?).to eq false
      end
    end

    describe "#generate_unsubscribe_hash" do
      let(:notification) { build(:notify_user_notification) }

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

    describe '#sendable_params' do
      let(:notification) { create(:notify_user_notification, params: {
        'foo' => 'bar',
        'bar' => 'baz',
        'quux' => 'quuz'
      }) }

      it 'falls back to params' do
        expect(notification.sendable_params).to eq ({
          'foo' => 'bar',
          'bar' => 'baz',
          'quux' => 'quuz'
        })
      end

      it 'filters to whitelisted attributes' do
        allow(NewPostNotification).to receive(:sendable_attributes) { [:foo, :bar] }

        expect(notification.sendable_params).to eq({
          'foo' => 'bar',
          'bar' => 'baz'
        })
      end
    end

    describe '#read?' do
      it 'returns true if the notification has had its read timestamp set' do
        notification = build(:notify_user_notification, read_at: Time.zone.now)
        expect(notification.read?).to eq true
      end

      it 'returns false if the notification hasnt been read yet' do
        notification = build(:notify_user_notification, read_at: nil)
        expect(notification.read?).to eq false
      end
    end

    describe '#mark_as_read!' do
      it 'sets the read timestamp of the notification' do
        notification = build(:notify_user_notification, read_at: nil)

        expect do
          notification.mark_as_read!
        end.to change(notification, :read_at).from(nil)
      end

      it 'saves the notification' do
        notification = build(:notify_user_notification, read_at: nil)

        expect do
          notification.mark_as_read!
          notification.reload
        end.to change(notification, :read_at).from(nil)
      end
    end

    describe '#parents_in_group' do
      let(:user) { create(:user) }

      context 'with grouping' do
        before :each do
          allow(NewPostNotification).to receive(:aggregate_grouping) { true }
        end

        it 'returns an empty collection if there are no parents' do
          notification = build(:notify_user_notification, target: user, group_id: 1)
          expect(notification.parents_in_group).to be_empty
        end

        it 'returns parents with the same group id as the current notiifcation' do
          parent = create(:notify_user_notification, target: user, group_id: 1)
          notification = build(:notify_user_notification, target: user, group_id: 1)

          expect(notification.parents_in_group).to match_array([parent])
        end

        it 'doesnt return child notifications from the same group' do
          parent = create(:notify_user_notification, target: user, group_id: 1)
          child = create(:notify_user_notification, target: user, group_id: 1, parent_id: parent.id)
          notification = build(:notify_user_notification, target: user, group_id: 1)

          expect(notification.parents_in_group).not_to include child
        end

        it 'doesnt return parents from a different group' do
          parent = create(:notify_user_notification, target: user, group_id: 1)
          notification = build(:notify_user_notification, target: user, group_id: 2)

          expect(notification.parents_in_group).not_to include parent
        end

        it 'doesnt return parents from a different target' do
          parent = create(:notify_user_notification, group_id: 1)
          notification = build(:notify_user_notification, target: user, group_id: 1)

          expect(notification.parents_in_group).not_to include parent
        end
      end

      context 'without grouping' do
        before :each do
          allow(NewPostNotification).to receive(:aggregate_grouping) { false }
        end

        it 'returns an empty collection' do
          notification = build(:notify_user_notification)
          expect(notification.parents_in_group).to be_empty
        end
      end
    end

    describe ".for_target" do
      let(:user) { create(:user) }

      it 'returns notifications for the specified target' do
        notification = create(:notify_user_notification, target: user)
        expect(described_class.for_target(user)).to include notification
      end

      it 'doesnt return notifications for other targets' do
        notification = create(:notify_user_notification)
        expect(described_class.for_target(user)).not_to include notification
      end
    end

    describe ".unread_count_for_target" do
      let(:user) { create(:user) }

      it "returns the current unread count for a user" do
        create(:notify_user_notification, target: user, read_at: nil)
        create(:notify_user_notification, target: user, read_at: Time.zone.now)

        expect(described_class.unread_count_for_target(user)).to eq 1
      end
    end

    describe '.sendable_attributes' do
      it 'has a default of an empty array' do
        class TestNotificationWithoutSendableAttributes < BaseNotification; end

        expect(TestNotificationWithoutSendableAttributes.sendable_attributes).to eq []
      end

      it 'can have configurable attributes' do
        class TestNotificationWithSendableAttributes < BaseNotification
          allow_sendable_attributes \
            :id,
            :foo
        end

        expect(TestNotificationWithSendableAttributes.sendable_attributes).to eq [:id, :foo]
      end
    end
  end
end
