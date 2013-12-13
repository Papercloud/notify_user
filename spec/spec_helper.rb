$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path('../support', __FILE__)

ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
require "bundler"
Bundler.setup

ENV['RAILS'] = '4.0.2'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] = File.expand_path("../rails/rails-#{ENV['RAILS']}", __FILE__)

# Create the test app if it doesn't exists
unless File.exists?(ENV['RAILS_ROOT'])
  system 'rake setup'
end


require 'rails/all'
require File.expand_path("#{ENV['RAILS_ROOT']}/config/environment.rb",  __FILE__)
# require ENV['RAILS_ROOT'] + '/config/environment'

require 'rspec/rails'
require 'factory_girl_rails'

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