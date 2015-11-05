require 'spec_helper'

module NotifyUser
  describe APNConnection do
    describe 'pem file paths' do
      before :each do
        @connection = described_class.new
      end

      it 'has the correct default development path' do
        expect(@connection.send(:development_certificate)).to eq "#{Rails.root}/config/keys/development_push.pem"
      end

      it 'has the correct default production path' do
        expect(@connection.send(:production_certificate)).to eq "#{Rails.root}/config/keys/production_push.pem"
      end

      it 'can set a custom path for development' do
        ENV['APN_DEVELOPMENT_PATH'] = 'path/to/key.pem'
        expect(@connection.send(:development_certificate)).to eq "#{Rails.root}/path/to/key.pem"
      end

      it 'can set a custom path for production' do
        ENV['APN_PRODUCTION_PATH'] = 'path/to/key.pem'
        expect(@connection.send(:production_certificate)).to eq "#{Rails.root}/path/to/key.pem"
      end
    end
  end
end