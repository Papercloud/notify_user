require 'spec_helper'

module NotifyUser
  describe ChannelPresenter do
    describe '#present' do
      before :each do
        user = create(:user)
        @notification = create_notification_for_user(user)
      end

      it 'returns the formatted notification message' do
        message = described_class.present(@notification)
        expect(message).to eq 'New Post Notification happened with {}'
      end
    end

    def create_notification_for_user(user, options = {})
      NewPostNotification.create({ target: user }.merge(options))
    end
  end
end
