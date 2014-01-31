require 'spec_helper'

describe "web notifications", :type => :request, :js => :true do

	let(:user) { User.create({email: "user@example.com" })}

	before :each do
	  NotifyUser::NotificationsController.any_instance.stub(:current_user).and_return(user)
	  NotifyUser::NotificationsController.any_instance.stub(:authenticate_user!).and_return(true)
	end

	describe "visit web notifications" do 

	  before :each do
	  	NotifyUser.send_notification('new_post_notification').to(user).with(name: "Mr. Blobby").notify
	  	@notification = NotifyUser::BaseNotification.last
	  end

	  it "returns a list of notifications" do
	    visit notify_user_notifications_path()
	    click_link(@notification.id)
	  end

	end

end
