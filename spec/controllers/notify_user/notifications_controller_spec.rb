require 'spec_helper'


describe NotifyUser::NotificationsController do

  let(:user) { User.create({email: "user@example.com" })}

  before :each do
    NotifyUser::NotificationsController.any_instance.stub(:current_user).and_return(user)
    NotifyUser::NotificationsController.any_instance.stub(:authenticate_user!).and_return(true)
  end

  it "delegates authentication to Devise" do
    subject.should_receive(:authenticate_user!).and_return(true)
    subject.should_receive(:current_user).and_return(user)
    get :index 
  end

  

end