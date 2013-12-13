require 'spec_helper'

describe "setup initializer" do

  it "sets a default mailer_sender" do
    NotifyUser.mailer_sender.should eq "please-change-me-at-config-initializers-notify-user@example.com"
  end
  
end