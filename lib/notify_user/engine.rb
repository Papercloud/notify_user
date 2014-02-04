module NotifyUser
  class Engine < ::Rails::Engine
  	require 'websocket-rails'

    # isolate_namespace NotifyUser ## KG: Not using this because views can be overriden and need the namespace

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
