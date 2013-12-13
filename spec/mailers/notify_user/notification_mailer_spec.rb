require "spec_helper"

describe NotifyUser::NotificationMailer do
  describe "notification_email" do

    let(:user) { User.new({email: "user@example.com" })}
    let(:notification) { NewPostNotification.new({target: user}) }
    let(:mailer) { NotifyUser::NotificationMailer.send(:new, 'notification_email', 1) }
    let(:mail) { mailer.notification_email(1) }

    before :each do
      NotifyUser::BaseNotification.stub(:find).and_return(notification)
    end

    it "renders the headers" do
      mail.subject.should eq(notification.subject)
      mail.to.should eq([user.email])
      mail.from.should eq([NotifyUser.mailer_sender])
    end

    it "renders the default template" do
      mailer_should_render_template(mailer, "notify_user/notification_mailer/notification_email")
    end

  end
end
