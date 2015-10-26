require 'spec_helper'

module NotifyUser
  describe NotificationMailer do
    describe 'notification_email' do
      let(:user) { build(:user) }
      let(:notification) { NewPostNotification.new(target: user) }
      let(:mailer) { NotificationMailer.send(:new, 'notification_email', notification, ActionMailerChannel.default_options) }
      let(:mail) { mailer.notification_email(notification, ActionMailerChannel.default_options) }

      before :each do
        allow(BaseNotification).to receive(:find).and_return(notification)
      end

      it 'renders the headers' do
        expect(mail.subject).to eq(ActionMailerChannel.default_options[:subject])
        expect(mail.to).to eq([user.email])
        expect(mail.from).to eq([NotifyUser.mailer_sender])
      end

      it "renders a template to render the notification's template as a partial" do
        mailer_should_render_template(mailer, 'notify_user/action_mailer/notification')
        mail
      end

      it 'renders with a layout' do
        allow_any_instance_of(NotificationMailer).to receive(:notification).and_return(notification)
        expect(mail.body.raw_source).to include 'This is the default generated layout'
      end
    end
  end
end
