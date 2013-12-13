# desc "Creates a test rails app for the specs to run against"
# task :setup do
#   require 'rails/version'
#   system("mkdir spec/rails") unless File.exists?("spec/rails")
#   ENV['RAILS'] = Rails::VERSION::STRING
#   create_dummy = "bundle exec rails _#{ENV['RAILS']}_ new spec/rails/rails-#{ENV['RAILS']} -m spec/support/rails_template.rb --skip-bundle"
#   puts "Running.."
#   puts create_dummy
#   system(create_dummy)
# end
