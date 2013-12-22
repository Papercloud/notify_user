require 'spec_helper'

describe NotifyUser::NotificationSerializer do

  it { should include_root(:notifications) }
  it { should have_attribute(:message) }
  it { should have_attribute(:id) }
  it { pending "implement unread/read state"}  #should have_attribute(:read)
  
end