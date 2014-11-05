# encoding: utf-8
class Pritory < Sinatra::Base
	get "/locale/:lang" do
		locale = params[:lang]
		session[:locale] = locale
		redirect request.referrer   
	end
end
