# encoding: utf-8
class Pritory < Sinatra::Base

  # Add Source
  get '/add_source' do
    protected
    user = User.first(username: session['name'])
    @products = user.products
    haml :add_source
  end

  # Post source
  post '/add_source' do
    protected
    pro = Product.find(name: params['name'])
    price_in_cents = MyHelpers.euro_to_cents(params['price'])
    begin
      pro.add_source(
        name: params['source'],
        price: price_in_cents,
        created_at: TZInfo::Timezone.get('Europe/Athens').now
      )
      redirect '/add_source'
      flash[:result] = "#{t 'source_added'}"
    rescue Sequel::Error => e
      settings.log.error("(route/source.rb:27) #{e}")
      flash[:error] = "#{e}"
      redirect '/add_source'
    end
  end

  # Delete source
  get '/delete_source/:id' do
    protected
    id = params['id'].delete(':')
    protected_source(id)
    begin
      product_id = Source.find(id: id).product_id
      Source.find(id: id).delete
      flash[:success] = "Η πηγή έχει διαγραφεί με επιτυχία από την βάση δεδομένων!"
      redirect "/view_product/:#{product_id}"
    rescue => e
      settings.log.error("(route/source.rb:44) #{e}")
      flash[:error] = "#{e}"
    end
  end

  # Add new price to the source
  get '/update_source_np/:id' do
    protected
    id = params['id'].delete(':')
    protected_source(id)
    begin
      a = Source.find(id: id)
      @source = a.name
      @pid = a.product_id
      @name = a.product[:name]
      @price = MyHelpers.cents_to_euro(a.price)
      haml :update_source_np
    rescue Exception => e
      settings.log.error("#{e}")
      flash[:error] = "#{e}"
      redirect '/panel'
    end
  end

  post '/update_source_np' do
    protected
    begin
      Source.create(name: params['source'], product_id: params['pid'], price: MyHelpers.euro_to_cents(params['price']), created_at: TZInfo::Timezone.get('Europe/Athens').now)
      redirect '/panel'
    rescue Exception => e
      settings.log.error("(route/source.rb:74) #{e}")
      flash[:error] = "#{e}"
      redirect '/panel'
    end
  end

  # Update current source price
  get '/update_source/:id' do
    protected
    id = params['id'].delete(':')
    protected_source(id)
    begin
      a = Source.find(id: id)
      @source = a.name
      @id = a.id
      @name = a.product[:name]
      @price = MyHelpers.cents_to_euro(a.price)
      haml :update_source
    rescue => e #StandardError
      settings.log.error("(route/source.rb:93) #{e}")
      flash[:error] = "#{e}"
      redirect '/panel'
    end
  end

  post '/update_source' do
    protected
    begin
      a = Source.find(id: params['id'])
      a.update(name: params['source'], price: MyHelpers.euro_to_cents(params['price']))
      redirect '/panel'
    rescue Exception => e
      settings.log.error("(route/source.rb:105) #{e}")
      flash[:error] = "#{e}"
      redirect '/panel'
    end
  end
end
