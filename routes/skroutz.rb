# encoding: utf-8
class Pritory < Sinatra::Base

  # Get category (step 1)
  get '/skroutz_add/:name' do
    protected!
    p @res = settings.squick.query_skroutz(@name)
    if @res["categories"].nil?
      redirect '/panel'
    else
      @name = params['name'].delete(':')
      haml :skroutz_add
    end
  end

  post '/skroutz_add' do
    values = params['category']
    redirect "/skroutz_add2/:#{values}"
  end

  # Choose from category and fetch price
  get '/skroutz_add2/:values' do
    values = params['values'].delete(':').split('_')
    id, name = values[0], values[1]
    tries = 3
    begin
      @res2 = settings.squick.query_skroutz2 id, name
      # Faraday::ConnectionFailed
      redirect '/manage_product' if @res2.nil?
      haml :skroutz_add2
    rescue Faraday::ConnectionFailed => e
      flash[:error] = "Αποτυχία σύνδεσης!"
      settings.log("Farrady connection failed for id: #{id} and name: #{name}, προσπάθεια #{tries}")
      if (tries -= 1) > 0
        retry
      else
        redirect '/panel'
        flash[:success] = "Προστέθηκε τιμή από skroutz!"
      end
    end
  end

  post '/skroutz_add2' do
    id = params['product_id'].to_i
    r = settings.squick.query_skroutz3 id
    price = r['products'][0]['price'].to_s
    source = Source.last
    Source.create(
      product_id: source.product_id,
      source: 'Skroutz',
      skroutz_id: id,
      price: MyHelpers.euro_to_cents(price),
      created_at: TZInfo::Timezone.get('Europe/Athens').now
    )
    redirect '/panel'
    flash[:success] = "Προστέθηκε τιμή από skroutz!"
  end
end
