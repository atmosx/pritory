# encoding: utf-8
class Pritory < Sinatra::Base

  # User logged in
  get "/panel" do
    protected!
    @user = User.first(username: session['name'])
    @products = @user.products
    haml :panel
  end

  # Add product
  get '/manage_product' do
    protected!
    user = User.first(username: session['name'])
    @products = user.products
    haml :manage_product
  end

  get '/view_product/:id' do
      protected!
      id = params['id'].delete(':')
      # Margin and MarkUp explained simply http://www.qwerty.gr/howto/margin-vs-markup
      @product = Product.find(id: id)
      @cost = MyHelpers.cents_to_euro(@product.cost)
      @price = MyHelpers.cents_to_euro(@product.source[0][:price])
      @price_plus_vat = MyHelpers.cents_to_euro(@product.source[0][:price] * ((@product.vat_category/100)+1))
      margin = (@product.source[0][:price] - @product.cost)/@product.source[0][:price]
      @markup = MyHelpers.cents_to_euro(@product.source[0][:price] - @product.cost)
      @margin = MyHelpers.numeric_to_percentage(margin)
      haml :view_product
  end
  
  # Post product
  post '/manage_product' do
    protected!
    user = User.first(username: session['name'])
    img = params['image']
    begin
      Product.create(
        user_id: user.id, 
        category: params['category'],
        vat_category: params['vat_category'].to_f,
        name: params['name'], 
        barcode: params['barcode'], 
        description: params['description'], 
        cost: MyHelpers.euro_to_cents(params['cost']), 
        notes: params['comment']
      )
      
      # Get product object
      a = Product.last
      
      Source.create(
        product_id: a.id,
        source: user.store_name,
        auto_update: false,
        price: MyHelpers.euro_to_cents(params['price'])
      )
      
      if img
        filename = params['image'][:filename]
        images = Dir['public/images/*']

        # Check for overwrites - DOESNT WORK
        if images.include? "public/images/#{filename}"
          raise ArgumentError.new("Παρακαλώ αλλάξτε όνομα στην εικόνα!") 
        end

        File.open('public/images/' + params['image'][:filename], "w") do |f|
           f.write(params['image'][:tempfile].read)
        end
        a.update(img_url: params['image'][:filename])
      end
      flash[:result] = "Το προϊόν προστέθηκε στην βάση δεδομένων"
      redirect "/skroutz_add/:#{params['name']}"
    rescue Sequel::Error => e
      flash[:error] = "#{e}"
      rediret "/manage_product"
    rescue ArgumentError => e
      flash[:error] = "#{e}"
      rediret "/manage_product"
    end
  end

  # Get category (step 1)
  get '/skroutz_add/:name' do
    protected!
    @name = params['name'].delete(':')
    # create object if doesn't exist
    # check instant access with threaded servers like puma!
    # Maybe we shouldn't be using global vars
    $squick ||= Skroutz::Query.new
    # get new token
    @res = $squick.query_skroutz(@name)
    haml :skroutz_add
  end

  post '/skroutz_add' do
    values = params['category']
    redirect "/skroutz_add2/:#{values}"
  end

  get '/skroutz_add2/:values' do
    values = params['values'].delete(':').split('_')
    id, name = values[0], values[1]
    redirect '/manage_product' if @res2.nil?
    @res2 = $squick.query_skroutz2 id, name
    haml :skroutz_add2
  end

  post '/skroutz_add2' do
    id = params['product_id']
    redirect "/skroutz_add3/:#{id}"
  end

  get '/skroutz_add3/:id' do
    id = params['id'].delete(':')
    @res3 = $squick.query_skroutz3 id
    haml :skroutz_add3
  end

  post '/skroutz_add3' do
    source = Source.last
    Source.create(
      product_id: source.product_id,
      source: 'Skroutz',
      auto_update: true,
      price: MyHelpers.euro_to_cents(params['product'])
    )
    redirect '/manage_product'
  end

  # Add Source
  get '/manage_source' do
    protected!
    user = User.first(username: session['name'])
    @products = user.products
    haml :manage_source
  end
  
  # Post source
  post '/manage_source' do
    protected!
    pro = Product.find(name: params['name'])
    price_in_cents = MyHelpers.euro_to_cents(params['price'])
    begin
      Source.create(
        product_id: pro.id,
        source: params['source'],
        price: price_in_cents
      )
      flash[:result] = "Η πηγή καταχωρήθηκε στην βάση δεδομένων"
      redirect '/manage_source'
    rescue Sequel::Error => e
      flash[:error] = "#{e}"
      redirect '/manage_source'
    end
  end

  # Delete source
  get '/delete_source/:id' do
    protected!
    id = params['id'].delete(':')
    begin
      product_id = Source.find(id: id).product_id
      Source.find(id: id).delete
      flash[:success] = "Η πηγή έχει διαγραφεί με επιτυχία από την βάση δεδομένων!"
      redirect "/view_product/:#{product_id}"
    rescue => e
      flash[:error] = "#{e}"
    end
  end
  
  # Delete Product
  get '/delete_product/:id' do
    begin
      id = params['id'].delete(':')
      product = Product.find(id: id)
      product.source.each do |s|
        s.delete
      end
      product.delete
      flash[:success] = "Το προϊόν έχει διαγραφεί με επιτυχία από την βάση δεδομένων!"
      redirect "/manage_product"
    rescue => e
      flash[:error] = "#{e}"
    end
  end

  # Update product
  get '/update/:id' do
    protected!
    haml :update
  end
end
