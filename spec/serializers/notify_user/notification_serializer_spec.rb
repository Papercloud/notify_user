require 'spec_helper'

describe NotifyUser::NotificationSerializer, type: :model do
  let(:resource) { create(:notify_user_notification) }
  let(:serializer) { described_class.new(resource) }
  let(:attributes) {[
    'id',
    'type',
    'message',
    'read',
    'params',
    'created_at',
  ]}

  subject do
    JSON.parse(serializer.to_json)
  end

  describe 'root' do
    it 'has a notifications root' do
      expect(subject['notifications']).not_to be_nil
    end

    it 'has the correct attributes in the root' do
      expect(subject['notifications'].keys).to match_array(attributes)
    end
  end
end