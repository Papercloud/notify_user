module NotifyUser
  class Engine < ::Rails::Engine
  	require 'active_model_serializers'

    initializer :append_migrations do |app| 
      if ActiveRecord::VERSION::MAJOR < 4
        app.config.paths["db/migrate"] += config.paths["db/migrate"].expanded
      else
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
