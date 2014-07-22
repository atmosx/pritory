# encoding: utf-8
class Pritory < Sinatra::Base
  
  # Main page
  get "/" do
    @title = "Pritory System"				
    haml :main
  end

  # Login user to panel
  post '/panel' do
    username, password = params['username'], params['password']
    if User.login_user_id(username, password)
      session_start!
      session[:name] = username
      flash[:success] = "Καλώς ορίσατε"
      redirect "/panel" 
    else
      flash[:error] = "Δεν βρέθηκε το όνομα χρήστη ή o κωδικός."
      redirect '/'
    end
  end

  # Logout
  get '/logout' do
    session_end!
    redirect '/'
  end
end
