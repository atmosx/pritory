# In Rspec-2.x '/spec' directory is loaded by default

# Load my configurations
require 'spec_helper'

describe 'Routes testing' do
	%w{ / }.each do |page|
		it "accessing '#{page}'" do
			get page
			expect(last_response).to be_ok
		end
	end

	it 'non existant page 404' do
		get '/non_existent_page'
		expect(last_response.status).to eq(404)
	end
end
