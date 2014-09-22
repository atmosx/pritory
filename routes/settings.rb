# encoding: utf-8
class Pritory < Sinatra::Base
  get '/settings' do
    protected!
    @username = User.first(username: session['name'])
    a = @username.setting
    a ||= {realname: 'Pikos Apikos', email: 'pikos@frouto.pia', country: 'Froutopia', storename: 'Lemonostyfen', skroutz_oauth_cid: '', skroutz_oauth_pas: ''}
    countries = [] ; Vat.each {|x| countries << x[:country]}
    @countries = countries.uniq
    @country = a[:country]
    @realname = a[:realname]
    @email = a[:email]
    @storename = a[:storename]
    @skroutz_cid = a[:skroutz_oauth_cid]
    @skroutz_pas = a[:skroutz_oauth_pas]
    haml :settings
  end

  post '/settings' do
    protected!
    user = User.first(username: session['name'])
    if user.setting.nil?
      Setting.create(
       user_id: user.id,
       country: params['country'],
       realname: params['realname'],
       email: params['email'],
       storename: params['storename'],
       skroutz_oauth_cid: params['skroutz_cid'],
       skroutz_oauth_pas: params['skroutz_pas']
      )
    else
      user.setting.update(
       country: params['country'],
       realname: params['realname'],
       email: params['email'],
       storename: params['storename'],
       skroutz_oauth_cid: params['skroutz_cid'],
       skroutz_oauth_pas: params['skroutz_pas']
      )
    end
    flash[:success] = "Οι ρυθμίσεις ενημερώθηκαν!"
    redirect '/settings'
  end
end

