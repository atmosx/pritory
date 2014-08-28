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
    @user = User.first(username: session['name'])
    @store = @user.store_name
    @product = Product.find(id: id)
    @cost = MyHelpers.cents_to_euro(@product.cost)
    @cost_plus_vat = MyHelpers.cents_to_euro(@product.cost * ((@product.vat_category/100)+1))
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
      a = Product.create(
        user_id: user.id, 
        category: params['category'],
        vat_category: params['vat_category'].to_f,
        name: params['name'], 
        barcode: params['barcode'], 
        description: params['description'], 
        cost: MyHelpers.euro_to_cents(params['cost']), 
        notes: params['comment']
      )
      # This technique is not safe if we have more than 1 users at the same time.
      Source.create(
        product_id: a.id,
        source: user.store_name,
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
      redirect "/manage_product"
    rescue ArgumentError => e
      flash[:error] = "#{e}"
      redirect "/manage_product"
    end
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
      redirect '/manage_source'
      flash[:result] = "Η πηγή καταχωρήθηκε στην βάση δεδομένων"
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
    protected!
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

  get '/update_source/:id' do
    protected!
    id = params['id'].delete(':')
    a = Source.find(id: id.to_i)
    @source = a.source
    @name = a.product[:name]
    @price = MyHelpers.cents_to_euro(a.price)
    haml :update_source
  end

  post '/update_source' do
    protected!
    a = Source.find(id: params['id'].to_i)
    a.update(source: params['source'], price: MyHelpers.cents_to_euro(params['price']))
  end

  # Update product
  get '/update_product/:id' do
    protected!
    @id = params['id'].delete(':')
    @product = Product.find(id: @id)
    @cost = MyHelpers.cents_to_euro(@product.cost)
    @price = MyHelpers.cents_to_euro(@product.source[0][:price])
    margin = (@product.source[0][:price] - @product.cost)/@product.source[0][:price]
    @markup = MyHelpers.cents_to_euro(@product.source[0][:price] - @product.cost)
    @margin = MyHelpers.numeric_to_percentage(margin)
    user = User.first(username: session['name'])
    img = params['image']
    haml :update_product
  end

  # Post product
  post '/update_product' do
    protected!
    img = params['image']
    a = Product.find(id: params['id'].to_i)
    user = User.first(username: session['name'])
    store = user.store_name
    begin
      a.update(
        category: params['category'],
        vat_category: params['vat_category'].to_f,
        name: params['name'], 
        barcode: params['barcode'], 
        description: params['description'], 
        cost: MyHelpers.euro_to_cents(params['cost']), 
        notes: params['comment']
      )

      # find source_id
      # NOTE: We could use a more elegant solution like: a.source_dataset.where(store: "Metropolis Pharmacy")
      sid = nil
      a.source.each do |entry|
        if (entry[:product_id] == params['id'].to_i && entry[:source] == store)
          sid = entry[:id]
        end
      end
      b = Source.find(id: sid)
      b.update(
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
      redirect "/view_product/:#{params['id'].to_i}"
    rescue Sequel::Error => e
      flash[:error] = "#{e}"
      redirect "/manage_product"
    rescue ArgumentError => e
      flash[:error] = "#{e}"
      redirect "/manage_product"
    end
  end
end
