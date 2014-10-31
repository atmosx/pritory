require 'rubygems'
require 'spork'
#require 'spork/ext/ruby-debug'

# Hardcode 'test' environment eitherwise the fuck it works!
ENV['RACK_ENV'] = 'test'

Spork.prefork do
  require 'rack/test'
  require 'capybara/rspec'
end

Spork.each_run do
  require File.expand_path '../../pritory.rb', __FILE__
end

module RSpecMixin
	include Rack::Test::Methods
	include Capybara::DSL

	# Rspec setup
	def app 
		Pritory 
	end

	# Capybara setup
	Capybara.app = Pritory
end

RSpec.configure do |c|
  set :run, false
  set :raise_errors, true
  set :logging, false
	c.include RSpecMixin
end
