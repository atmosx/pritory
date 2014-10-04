# encoding: utf-8
class Pritory < Sinatra::Base
  
  # Main page
  get "/" do
    @title = "Σύστημα Pritory"				
    haml :main
  end

  # Logout
  get '/logout' do
    session_end!
    flash[:success] = "Έχετε αποσυνδεθεί από το σύστημα"
    redirect '/'
  end
end
