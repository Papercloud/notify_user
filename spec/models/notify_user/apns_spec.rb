require 'spec_helper'

describe NotifyUser::Apns do
  let(:user) { User.create({email: 'user@example.com' })}
  let(:notification) { NewPostNotification.create({target: user}) }

  before :each do
    allow_any_instance_of(NotifyUser::BaseNotification).to receive(:mobile_message).and_return('New Notification')
    allow_any_instance_of(NotifyUser::Gcm).to receive(:device_tokens).and_return('a_token')
  end

  describe "initialisation" do
    it "should initialise the correct push options" do
      @apns = NotifyUser::Apns.new([notification], [], {})

      expect(@apns.push_options[:alert]).to eq 'New Notification'
      expect(@apns.push_options[:badge]).to eq 1
      expect(@apns.push_options[:category]).to eq 'NewPostNotification'
      expect(@apns.push_options[:custom_data]).to be_empty
      expect(@apns.push_options[:sound]).to eq 'default'
    end

    it 'should access the notification targets list of devices' do
      expect(user).to receive(:devices)

      @apns = NotifyUser::Apns.new([notification], [], {})
    end

    it 'should use the sound specified in the options' do
      @apns = NotifyUser::Apns.new([notification], [], { sound: 'special.wav' })

      expect(@apns.push_options[:sound]).to eq 'special.wav'
    end

    it 'should remove the badge key for silent notifications' do
      @apns = NotifyUser::Apns.new([notification], [], { silent: true })

      expect(@apns.push_options).not_to have_key(:badge)
    end

    xit "should initialize with many notifications" do
      expect(NotifyUser::BaseNotification).to receive(:aggregate_message).and_return("New Notification")
      notifications = NewPostNotification.create([{target: user}, {target: user}, {target: user}])

      NotifyUser::Apns.new(notifications, [], {})
    end
  end
end