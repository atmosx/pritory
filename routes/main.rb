# encoding: utf-8
class Pritory < Sinatra::Base

  # Main page
  get "/" do
    redirect '/panel' if session?
    haml :main
  end

  # Login user to panel
  post '/panel' do
    username, password = params['username'], params['password']
    if User.login_user_id(username, password)
      session_start!
      session[:name] = username
      flash[:success] = "#{t 'welcome_message'}"
      redirect "/panel" 
    else
      # fix this IP variable at some point in time.
      settings.log.error("[SECURITY]: bad username and password from <IP>")
      flash[:error] = "#{t 'login_failed_message'}"
      redirect '/'
    end
  end

  # Logout
  get '/logout' do
    session_end!
    flash[:success] = "#{t 'logout_message'}"
    redirect '/'
  end
end
