#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path '../../pritory.rb', __FILE__
require 'rack/test'
require 'capybara/rspec'

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
	c.include RSpecMixin
  set :environment, :test
  set :run, false
  set :raise_errors, true
  set :logging, false
end
