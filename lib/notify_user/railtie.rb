class Railtie < ::Rails::Railtie
  initializer "notify_user.setup_assets" do |app|
    app.config.assets.precompile += %w( notify_user/notify_user.css )
  end

    rake_tasks do
    	gem_dir = File.expand_path('..',File.dirname(__FILE__))
    	load "#{gem_dir}/tasks/notify_user.rake"
    end
end