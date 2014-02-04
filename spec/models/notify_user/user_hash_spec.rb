require 'spec_helper'

module NotifyUser
  describe UserHash do

    let(:user) { User.create({email: "user@example.com" })}
    let(:user_hash) { NotifyUser::UserHash.create({target: user, type: "NewPostNotification"})}

    describe "check hash" do
      before :each do
        user_hash.save
      end
      
      it "returns true if hash hasn't be used before" do
        NotifyUser::UserHash.confirm_hash(user_hash.token,"NewPostNotification").should eq true
      end

      it "returns false if hash has been used before" do
        user_hash.deactivate
        NotifyUser::UserHash.confirm_hash(user_hash.token,"NewPostNotification").should eq false
      end

      it "deactivates hash setting active to false" do
        user_hash.deactivate
        user_hash.active.should eq false
      end

      it "generates a 44 character hash on create" do
        user_hash.token.length.should eq 44
      end

    end

  end
end
