$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "notify_user/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "notify_user"
  s.version     = NotifyUser::VERSION
  s.authors     = ["Tom Spacek"]
  s.email       = ["ts@papercloud.com.au"]
  s.homepage    = "http://www.papercloud.com.au"
  s.summary     = "A Rails engine for user notifications."
  s.description = "Drop-in solution for user notifications. Handles notifying by email, SMS and APNS, plus per-user notification frequency settings and views for checking new notifications."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "state_machine"
  s.add_dependency "sidekiq"
  s.add_dependency "kaminari"
  s.add_dependency "active_model_serializers"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-sidekiq"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "awesome_print"

  s.test_files = Dir["spec/**/*"]
end
