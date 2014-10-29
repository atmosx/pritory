# Rakefile
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :start do
	conf = File.expand_path('config.ru', File.dirname(__FILE__))
	exec("rerun thin -R #{conf} --debug start")
end

# default
task default: :spec
