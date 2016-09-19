require 'spec_helper'

module NotifyUser
  describe Unsubscribe do
    let(:user) { create(:user) }
    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: 'Mr. Blobby') }
    let(:unsubscribe) { Unsubscribe.create(target: user, type: 'NewPostNotification') }

    before :each do
      allow(Scheduler).to receive(:schedule)
    end

    describe '.unsubscribe!' do
      it "creates unsubscribe object if it doesn't exist" do
        expect do
          Unsubscribe.unsubscribe!(user, 'NewPostNotification')
        end.to change(Unsubscribe, :count).by(1)
      end

      it "doesn't create if already exists" do
        Unsubscribe.unsubscribe!(user, 'NewPostNotification')
        expect do
          Unsubscribe.unsubscribe!(user, 'NewPostNotification')
        end.not_to change(Unsubscribe, :count)
      end
    end

    describe '.subscribe!' do
      it 'removes unsubscribe if exists for type' do
        Unsubscribe.unsubscribe!(user, 'NewPostNotification')

        expect do
          Unsubscribe.subscribe!(user, 'NewPostNotification')
        end.to change(Unsubscribe, :count).by(-1)
      end

      it "doesn't remove unsubscribe for another type" do
        Unsubscribe.unsubscribe!(user, 'AnotherPostNotification')

        expect do
          Unsubscribe.subscribe!(user, 'NewPostNotification')
        end.not_to change(Unsubscribe, :count)
      end

      it 'removes unsubscribe object if exists for type and group_id' do
        Unsubscribe.unsubscribe!(user, 'NewPostNotification', 1)

        expect do
          Unsubscribe.subscribe!(user, 'NewPostNotification', 1)
        end.to change(Unsubscribe, :count).by(-1)
      end

      it "doesn't remove unsubscribe object for another group_id" do
        Unsubscribe.subscribe!(user, 'NewPostNotification', 1)
        expect do
          Unsubscribe.subscribe!(user, 'NewPostNotification', 2)
        end.not_to change(Unsubscribe, :count)
      end
    end
  end
end
