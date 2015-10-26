require 'spec_helper'

describe "setup initializer" do

  it "sets a default mailer_sender" do
    expect(NotifyUser.mailer_sender).to eq "please-change-me-at-config-initializers-notify-user@example.com"
  end

  it "sets an authentication method" do
    expect(NotifyUser.authentication_method).to eq :authenticate_user!
  end

  it "sets a current user method" do
    expect(NotifyUser.current_user_method).to eq :current_user
  end
end