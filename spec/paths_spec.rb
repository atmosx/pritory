# In Rspec-2.x '/spec' loaded by default
require 'spec_helper'

describe "Routes testing" do

	# testing standard paths
	%w{ / }.each do |page|
		it "accessing '#{page}' page" do
			get page
			last_response.should be_ok
		end
	end

	it "should get 404" do
		get '/non_existent_page'
		last_response.status.should == 404
	end

	# it "should get 'not authorized'" do
		# get '/admin'
		# last_response.status.should == 401 # 401 = not authorized in http lang
	# end
end
