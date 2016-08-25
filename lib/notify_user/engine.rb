module NotifyUser
  class Engine < ::Rails::Engine
  	require 'active_model_serializers'

    config.to_prepare do
      Rails.application.config.assets.precompile += %w(
        notify_user/notification.js
      )
    end

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
