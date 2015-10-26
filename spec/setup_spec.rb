require 'spec_helper'

describe "setup initializer" do

  it "sets a default mailer_sender" do
    NotifyUser.mailer_sender.should eq "please-change-me-at-config-initializers-notify-user@example.com"
  end

  it "sets an authentication method" do
    NotifyUser.authentication_method.should eq :authenticate_user!
  end

  it "sets a current user method" do
    NotifyUser.current_user_method.should eq :current_user
  end
end