# encoding: utf-8
class Pritory < Sinatra::Base
  get '/settings' do

    protected

    @username = User.first(username: session['name'])
    a = @username.setting
    a ||= {realname: 'Pikos Apikos', currency: 'EUR', email: 'pikos@frouto.pia', country: 'Froutopia', storename: 'Lemonostyfen'}
    countries = [] ; Vat.each {|x| countries << x[:country]}
    @countries = countries.uniq
    @country = a[:country]
    @currency = a[:currency]
    @realname = a[:realname]
    @email = a[:email]
    @storename = a[:storename]
    haml :settings
  end

  post '/settings' do

    protected

    user = User.first(username: session['name'])
    if user.setting.nil?
      Setting.create(
       user_id: user.id,
       country: params['country'],
       currency: params['currency'],
       realname: params['realname'],
       email: params['email'],
       storename: params['storename']
      )
    else
      old_storename_name = user.setting.storename
      user.setting.update(
       country: params['country'],
       currency: params['currency'],
       realname: params['realname'],
       email: params['email'],
       storename: params['storename']
      )
      new_storename_name = user.setting.storename
      if old_storename_name != new_storename_name
        user.products.each do |p|
          p.sources.each do |s|
            s.update(source: new_storename_name) if s[:source] == old_storename_name
          end
        end
      end
    end
    flash[:success] = "Οι ρυθμίσεις ενημερώθηκαν!"
    redirect '/settings'
  end
end

