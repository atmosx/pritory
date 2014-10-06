# encoding: utf-8
class Pritory < Sinatra::Base

  # Main page
  get "/" do
    @title = "Σύστημα Pritory"				
    haml :main
  end

  # Login user to panel
  post '/panel' do
    username, password = params['username'], params['password']
    if User.login_user_id(username, password)
      session_start!
      session[:name] = username
      flash[:success] = "Καλώς ορίσατε στο Pritory!"
      redirect "/panel" 
    else
      # fix this IP variable at some point in time.
      settings.log.error("[SECURITY]: bad username and password from <IP>")
      flash[:error] = "Δεν βρέθηκε το όνομα χρήστη ή o κωδικός"
      redirect '/'
    end
  end

  # Logout
  get '/logout' do
    session_end!
    flash[:success] = "Έχετε αποσυνδεθεί από το σύστημα"
    redirect '/'
  end
end
