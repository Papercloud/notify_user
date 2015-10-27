begin
  require 'bundler/setup'
  require 'appraisal'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rake'
Bundler.setup
Bundler::GemHelper.install_tasks

def cmd(command)
  puts command
  raise unless system command
end

# Import all our rake tasks
FileList['tasks/**/*.rake'].each { |task| import task }
