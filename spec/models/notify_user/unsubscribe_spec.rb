require 'spec_helper'

module NotifyUser
  describe Unsubscribe do
    let(:user) { create(:user) }
    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Blobby') }
    let(:unsubscribe) { Unsubscribe.create(target: user, type: 'NewPostNotification') }

    before :each do
      allow(Scheduler).to receive(:schedule)
    end

    describe 'self.unsubscribe' do
      it "creates unsubscribe object if it doesn't exist" do
        expect do
          Unsubscribe.unsubscribe(user, 'NewPostNotification')
        end.to change(Unsubscribe, :count).by(1)
      end

      it "doesn't create if already exists" do
        Unsubscribe.unsubscribe(user, 'NewPostNotification')
        expect do
          Unsubscribe.unsubscribe(user, 'NewPostNotification')
        end.not_to change(Unsubscribe, :count)
      end
    end

    describe 'self.subscribe' do
      it 'removes unsubscribe if exists for type' do
        Unsubscribe.create(target: user, type: 'NewPostNotification')

        expect do
          Unsubscribe.subscribe(user, 'NewPostNotification')
        end.to change(Unsubscribe, :count).by(-1)
      end

      it "doesn't remove unsubscribe for another type" do
        Unsubscribe.create(target: user, type: 'AnotherPostNotification')

        expect do
          Unsubscribe.subscribe(user, 'NewPostNotification')
        end.not_to change(Unsubscribe, :count)
      end

      it 'removes unsubscribe object if exists for type and group_id' do
        Unsubscribe.create(target: user, type: 'NewPostNotification', group_id: 1)
        expect do
          Unsubscribe.subscribe(user, 'NewPostNotification', 1)
        end.to change(Unsubscribe, :count).by(-1)
      end

      it "doesn't remove unsubscribe object for another group_id" do
        Unsubscribe.create(target: user, type: 'NewPostNotification', group_id: 1)
        expect do
          Unsubscribe.subscribe(user, 'NewPostNotification', 2)
        end.not_to change(Unsubscribe, :count)
      end
    end

    describe 'unsubscribed' do
      before :each do
        unsubscribe
      end

      it "doesn't create notification object if unsubscribed" do
        expect(notification).to_not be_valid
      end

      it "doesn't queue an aggregation background worker if unsubscribed" do
        expect(notification.class).not_to receive(:delay_for)
        notification.notify
      end

      it 'toggles the status of a subscription' do
        Unsubscribe.create(target: user, type: 'NewPostNotification')
        Unsubscribe.toggle_status(user, 'NewPostNotification')
        expect(Unsubscribe.has_unsubscribed_from?(user, 'NewPostNotification')).to eq false
      end
    end

    describe 'subscribed' do
      it 'valid if unsubscribe is not present' do
        expect(notification).to be_valid
      end
    end
  end
end
