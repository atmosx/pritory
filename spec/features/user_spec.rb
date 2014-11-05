require 'spec_helper'

feature "user login and browse paths" do
	before :each do
    User.create(username: 'test', password: 'test') if User.find(username: 'test').nil? 
		visit '/'
		within ('#content') do 
			fill_in :username, with: 'test'
			fill_in :password, with: 'test'
			click_button 'Submit'
		end
	end
	
# 	scenario "access main page" do
# 		visit '/main'
# 		expect(page).to have_content 'Panel Add product Add source Settings Logout'
# 	end

# 	scenario "access add product" do
# 		visit '/add_product'
# 		expect(page).to have_content 'VAT'
# 	end
end
