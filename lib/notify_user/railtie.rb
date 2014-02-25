class Railtie < ::Rails::Railtie
  initializer "notify_user.setup_assets" do |app|
    app.config.assets.precompile += %w( notify_user/notify_user.css )
  end
end