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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "aasm"
  s.add_dependency "que"
  s.add_dependency "kaminari"
  s.add_dependency "active_model_serializers", "0.9.3"
  s.add_dependency "pubnub"
  s.add_dependency "houston"
  s.add_dependency "connection_pool"
  s.add_dependency "gcm"

  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-sidekiq"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "awesome_print"
  s.add_development_dependency "test_after_commit"
  s.add_development_dependency "pry"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "timecop"

  s.test_files = Dir["spec/**/*"]
end
