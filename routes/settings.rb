# encoding: utf-8
class Pritory < Sinatra::Base
  get '/settings' do
    protected!
    @user = User.first(username: session['name'])

    haml :settings
  end
end
