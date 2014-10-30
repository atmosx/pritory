# encoding: utf-8
class Pritory < Sinatra::Base
  protected

	# This page is determines the sesion locale and redirects back to referrer
	get "/plugins" do
    haml :plugins
	end
end
