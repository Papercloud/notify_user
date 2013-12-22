require 'spec_helper'


describe NotifyUser::NotificationsController do

  let(:user) { User.create({email: "user@example.com" })}

  before :each do
    NotifyUser::NotificationsController.any_instance.stub(:current_user).and_return(user)
    NotifyUser::NotificationsController.any_instance.stub(:authenticate_user!).and_return(true)
  end

  it "delegates authentication to Devise" do
    subject.should_receive(:authenticate_user!).and_return(true)
    subject.should_receive(:current_user).any_number_of_times.and_return(user)
    get :index
  end

  describe "GET notifications.json" do
    render_views

    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }

    before :each do
      notification.save
    end

    it "returns a message from a rendered template" do
      get :index
      json[:notifications][0][:message].should include "New Post Notification happened with"
      json[:notifications][0][:message].should include notification.params[:name]
    end
  end

  describe "PUT notifications/mark_read.json" do
    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }

    before :each do
      notification.save
    end

    it "marks notifications as read" do
      put :mark_read, ids: [notification.id]
      notification.reload
      notification.read?.should eq true
    end

    it "returns updated notifications" do
      put :mark_read, ids: [notification.id]
      json[:notifications][0].should_not be_nil
    end
  end

end