require 'sinatra/session'

# encoding: utf-8
class Pritory < Sinatra::Base
	# This page is determines the sesion locale and redirects back to referrer
	get "/locale/:lang" do
		locale = params[:lang]
		session[:locale] = locale
		redirect request.referrer   
	end
end
