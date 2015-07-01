require 'spec_helper'

module NotifyUser
  describe Unsubscribe do

    let(:user) { User.create({email: "user@example.com" })}
    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }
    let(:unsubscribe) { Unsubscribe.create({target: user, type: "NewPostNotification"}) }

    describe "self.unsubscribe" do
      it "creates unsubscribe object if it doesn't exist"

      it "doesn't create if already exists"
    end

    describe "self.subscribe" do
      it "removes unsubscribe if exists for type" do
        Unsubscribe.create({target: user, type: "NewPostNotification"})

        expect{
          Unsubscribe.subscribe(user, "NewPostNotification")
        }.to change(Unsubscribe, :count).by(-1)
      end

      it "doesn't remove unsubscribe for another type" do
        Unsubscribe.create({target: user, type: "AnotherPostNotification"})

        expect{
          Unsubscribe.subscribe(user, "NewPostNotification")
        }.to change(Unsubscribe, :count).by(0)
      end

      it "removes unsubscribe object if exists for type and group_id" do
        Unsubscribe.create({target: user, type: "NewPostNotification", group_id: 1})
        expect{
          Unsubscribe.subscribe(user, "NewPostNotification", 1)
        }.to change(Unsubscribe, :count).by(-1)
      end

      it "doesn't remove unsubscribe object for another group_id" do
        Unsubscribe.create({target: user, type: "NewPostNotification", group_id: 1})
        expect{
          Unsubscribe.subscribe(user, "NewPostNotification", 2)
        }.to change(Unsubscribe, :count).by(0)
      end
    end


    describe "unsubscribed" do
      before :each do
        unsubscribe
      end

      it "doesn't create notification object if unsubscribed" do
        expect(notification).to_not be_valid
      end

      it "doesn't queue an aggregation background worker if unsubscribed" do
        notification.class.should_not_receive(:delay_for)
        notification.notify
      end

      it "toggles the status of a subscription" do
        unsubscribe = NotifyUser::Unsubscribe.create({target: user, type: "NewPostNotification"})
        NotifyUser::Unsubscribe.toggle_status(user, "NewPostNotification")
        NotifyUser::Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification').should eq []
      end
    end

    describe "subscribed" do
      it "valid if unsubscribe is not present" do
        expect(notification).to be_valid
      end
    end

  end
end
