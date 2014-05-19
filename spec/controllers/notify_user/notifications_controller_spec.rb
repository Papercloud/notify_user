require 'spec_helper'


describe NotifyUser::NotificationsController do

  let(:user) { User.create({email: "user@example.com" })}

  before :each do
    NotifyUser::NotificationsController.any_instance.stub(:current_user).and_return(user)
    NotifyUser::NotificationsController.any_instance.stub(:authenticate_user!).and_return(true)
  end

  it "delegates authentication to Devise" do
    subject.should_receive(:authenticate_user!).and_return(true)
    subject.stub(:current_user).and_return(user)
    get :index
  end

  describe "GET notifications.json" do
    render_views

    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }

    before :each do
      notification.save
    end

    it "returns a message from a rendered template" do
      get :index, :format => :json
      json[:notifications][0][:message].should include "New Post Notification happened with"
      json[:notifications][0][:message].should include notification.params[:name]
    end
  end

  describe "GET web Index notifications" do 
    render_views

    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }
    let(:notification1) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Adams") }
    let(:notification2) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mrs. James") }

    before :each do
      notification.save
      notification1.save
      notification2.save
    end

    it "returns a list of notifications" do
      NotifyUser::BaseNotification.any_instance.stub(:message).and_return("Mr. Blobby")
      get :index
      response.body.should have_content("Mr. Blobby")
    end

    it "reading a notification marks it as read and takes to redirect action" do
      get :read, :id => notification.id
      @notification = NotifyUser::BaseNotification.where(id: notification.id).first
      @notification.state.should eq "read"
      response.body.should have_content("set redirect logic")
    end

    it "reading a notification twice doesn't throw an exception" do
      get :read, :id => notification.id
      get :read, :id => notification.id
      
    end

    it "marks all unread messages as read" do
      get :mark_all
      notifications = NotifyUser::BaseNotification.for_target(user).where('state IN (?)', '["pending","sent"]')
      notifications.length.should eq 0
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

  describe "unsubscribing and subscribing" do
    let(:notification) { NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby") }

    before :each do
      notification.save
    end

    it "endpoint for updating notification subscription statuses" do
      NotifyUser::Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification').should eq []
      put :subscriptions, :types => [{
        type: 'NewPostNotification',
        status: '0'
        }]
      NotifyUser::Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification').should_not eq []        
    end

    it "endpoint for updating notification subscription statuses passing 1 does nothing" do
      NotifyUser::Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification').should eq []
      put :subscriptions, :types => [{
        type: 'NewPostNotification',
        status: '1'
        }]
      NotifyUser::Unsubscribe.has_unsubscribed_from(user, 'NewPostNotification').should eq []        
    end

    it "unsubscribing from notification type" do
      get :unsubscribe, :type => "NewPostNotification"
      NotifyUser::Unsubscribe.last.type.should eq "NewPostNotification"
    end

    it "subscribing deletes the unsubscribe object" do
      #lack of unsubscribe object implies the user is subscribed
      NotifyUser::Unsubscribe.create(target: user, type: "NewPostNotification")
      get :subscribe, :type => "NewPostNotification"
      NotifyUser::Unsubscribe.all.should eq []

    end

    it "verifies user token before unsubscribe then deactivates that token" do
      user_hash = notification.generate_unsubscribe_hash
      get :unauth_unsubscribe, :type => "NewPostNotification", :token => user_hash.token

      user_hash = NotifyUser::UserHash.last
      user_hash.active.should eq false
    end

  end

end