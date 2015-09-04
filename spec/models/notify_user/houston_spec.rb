require 'spec_helper'

module NotifyUser
  describe Houston do

    let(:user) { User.create({email: 'user@example.com' })}
    let(:notification) { NewPostNotification.create({target: user}) }

    before :each do
      allow_any_instance_of(BaseNotification).to receive(:mobile_message).and_return('New Notification')
      allow_any_instance_of(User).to receive(:devices).and_return(double('device'))
    end

    describe "initialisation" do
      it "should initialise the correct push options" do
        @houston = NotifyUser::Houston.new([notification], {})

        expect(@houston.push_options[:alert]).to eq 'New Notification'
        expect(@houston.push_options[:badge]).to eq 1
        expect(@houston.push_options[:category]).to eq 'NewPostNotification'
        expect(@houston.push_options[:custom_data]).to be_empty
        expect(@houston.push_options[:sound]).to eq 'default'
      end

      it 'should access the notification targets list of devices' do
        expect(user).to receive(:devices)

        @houston = NotifyUser::Houston.new([notification], {})
      end

      it 'should use the sound specified in the options' do
        @houston = NotifyUser::Houston.new([notification], { sound: 'special.wav' })

        expect(@houston.push_options[:sound]).to eq 'special.wav'
      end

      it 'should remove the badge key for silent notifications' do
        @houston = NotifyUser::Houston.new([notification], { silent: true })

        expect(@houston.push_options).not_to have_key(:badge)
      end

      xit "should initialize with many notifications" do
        expect(NotifyUser::BaseNotification).to receive(:aggregate_message).and_return("New Notification")
        notifications = NewPostNotification.create([{target: user}, {target: user}, {target: user}])

        NotifyUser::Houston.new(notifications, {})
      end
    end

  end
end