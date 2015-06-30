require 'spec_helper'

module NotifyUser
  describe Unsubscribe do

    let(:user) { User.create({email: "user@example.com" })}
    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }
    let(:unsubscribe) { NotifyUser::Unsubscribe.create({target: user, type: "NewPostNotification"}) }


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
