require 'spec_helper'

module NotifyUser
  describe UserHash do
    let(:user) { create(:user) }
    let(:user_hash) { UserHash.create(target: user, type: 'NewPostNotification') }

    describe 'check hash' do
      before :each do
        user_hash.save
      end

      it "returns true if hash hasn't be used before" do
        expect(UserHash.confirm_hash(user_hash.token, 'NewPostNotification')).to eq true
      end

      it 'returns false if hash has been used before' do
        user_hash.deactivate
        expect(UserHash.confirm_hash(user_hash.token, 'NewPostNotification')).to eq false
      end

      it 'deactivates hash setting active to false' do
        user_hash.deactivate
        expect(user_hash.active).to eq false
      end

      it 'generates a 44 character hash on create' do
        expect(user_hash.token.length).to eq 44
      end
    end
  end
end
