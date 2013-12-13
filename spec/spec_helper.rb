$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path('../support', __FILE__)

ENV['BUNDLE_GEMFILE'] ||= 'gemfiles/rails40.gemfile'

ENV['BUNDLE_GEMFILE'] = File.expand_path(File.join("../../", ENV['BUNDLE_GEMFILE']), __FILE__)
require "bundler"
Bundler.setup

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] = File.expand_path("../dummy/rails-#{ENV['RAILS_VERSION']}", __FILE__)

# Create the test app if it doesn't exists
unless File.exists?(ENV['RAILS_ROOT'])
  system 'rake setup'
end

require 'rails/all'
require 'sidekiq'
require File.expand_path("#{ENV['RAILS_ROOT']}/config/environment.rb",  __FILE__)

puts "Testing with Rails #{Rails::VERSION::STRING} and Ruby #{RUBY_VERSION}"

require 'rspec/rails'
require 'factory_girl_rails'
require 'sidekiq/testing'
Sidekiq::Testing.inline!

RSpec.configure do |config|
  config.infer_base_class_for_anonymous_controllers = false
  config.use_transactional_fixtures = true

  def mailer_should_render_template(mailer, template)
    mailer.should_receive(:_render_template) do |arg|
      arg[:template].virtual_path.should eq template
    end.and_call_original
    mailer.mail
  end

end