# encoding: utf-8
class Pritory < Sinatra::Base
  get '/settings' do
    protected!
    a = User.first(username: session['name']).setting
    a ||= {realname: 'Pikos Apikos', email: 'pikos@frouto.pia', storename: 'Lemonostyfen', skroutz_oauth_cid: '', skroutz_oauth_pas: ''}
    countries = [] ; Vat.each {|x| countries << x[:country]}
    @countries = countries.uniq
    @realname = a[:realname]
    @email = a[:email]
    @storename = a[:store_name]
    @skroutz_cid = a[:skroutz_oauth_cid]
    @skroutz_pas = a[:skroutz_oauth_pas]
    haml :settings
  end
end
