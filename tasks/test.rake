desc "Creates a test rails app for the specs to run against"
task :setup do
  system("mkdir spec/dummy") unless File.exists?("spec/dummy")

  create_dummy = "bundle exec rails new #{ENV['RAILS_ROOT']} -m spec/support/rails_template.rb -d postgresql --skip-bundle "
  puts "Running '#{create_dummy}'"
  system(create_dummy)

end
