# encoding: utf-8
class Pritory < Sinatra::Base

  # Get category (step 1)
  get '/skroutz_add/:name' do
    protected!
    @name = params['name'].delete(':')
    # create object if doesn't exist
    # check instant access with threaded servers like puma!
    @res = settings.squick.query_skroutz(@name)
    haml :skroutz_add
  end

  post '/skroutz_add' do
    values = params['category']
    redirect "/skroutz_add2/:#{values}"
  end

  get '/skroutz_add2/:values' do
    values = params['values'].delete(':').split('_')
    id, name = values[0], values[1]
    @res2 = settings.squick.query_skroutz2 id, name
    redirect '/manage_product' if @res2.nil?
    haml :skroutz_add2
  end

  post '/skroutz_add2' do
    id = params['product_id']
    redirect "/skroutz_add3/:#{id}"
  end

  get '/skroutz_add3/:id' do
    id = params['id'].delete(':')
    @res3 = settings.squick.query_skroutz3 id
    # redirect '/manage_product' if @res2.nil?
    haml :skroutz_add3
  end

  post '/skroutz_add3' do
    source = Source.last
    Source.create(
      product_id: source.product_id,
      source: 'Skroutz',
      auto_update: true,
      price: MyHelpers.euro_to_cents(params['price'])
    )
    redirect '/manage_product'
    flash[:result] = "Προστέθηκε τιμή από skroutz!"
  end

end
