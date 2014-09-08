# encoding: utf-8
class Pritory < Sinatra::Base

  # User panel
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
    protected_product!(id)
    @user = User.first(username: session['name'])
    @store = @user.store_name
    @product = Product.find(id: id)
    if @product.nil?
      flash[:error] = "Το προϊόν που ψάχνετε δεν υπάρχει!"
      settings.log.warn("[SECURITY] user #{@user} tried to access product that doesn't exist, with id #{id}!")
      redirect '/panel'
    end
    @cost = MyHelpers.cents_to_euro(@product.cost)
    @cost_plus_vat = MyHelpers.cents_to_euro(@product.cost * ((@product.vat_category/100)+1))
    # Sort prices for products on our store. Display the latest is '.last'
    sorted = @product.source_dataset.where(source: @store).sort_by {|h| h[:created_at]}
    @price = MyHelpers.cents_to_euro(sorted.last[:price])
    @price_plus_vat = MyHelpers.cents_to_euro(sorted.last[:price] * ((@product.vat_category/100)+1))
    list_of_sources = []
    @product.source.each {|e| list_of_sources << e[:source] unless list_of_sources.include? e[:source]}
    @latest_prices = [] 
    list_of_sources.each do |s|
      sorted = @product.source_dataset.where(source: s).sort_by {|h| h[:created_at]}
      @latest_prices << sorted.last
    end
    # Margin and MarkUp explained simply http://www.qwerty.gr/howto/margin-vs-markup
    margin = (sorted.last[:price] - @product.cost)/@product.source[0][:price]
    @markup = MyHelpers.cents_to_euro(sorted.last[:price] - @product.cost)
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
        notes: params['comment'],
        created_at: TZInfo::Timezone.get('Europe/Athens').now
      )
      Source.create(
        product_id: a.id,
        source: user.store_name,
        price: MyHelpers.euro_to_cents(params['price']),
        created_at: TZInfo::Timezone.get('Europe/Athens').now
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
      flash[:success] = "Το προϊόν προστέθηκε στην βάση δεδομένων"
      redirect "/skroutz_add/:#{params['name']}"
    rescue Sequel::Error => e
      flash[:error] = "An SQL error occured!"
      settings.log.error("ERROR SQL: #{e}")
      redirect "/manage_product"
    rescue ArgumentError => e
      flash[:error] = "ArgumentError occured!"
      settings.log.error("ERROR ArgumentError: #{e}")
      redirect "/manage_product"
    end
  end

  # Delete Product
  get '/delete_product/:id' do
    protected!
    id = params['id'].delete(':')
    protected_product!(id)
    begin
      product = Product.find(id: id)
      product.source.each {|s| s.delete}
      product.delete
      flash[:success] = "Το προϊόν έχει διαγραφεί με επιτυχία από την βάση δεδομένων!"
      redirect "/panel"
    rescue => e
      flash[:error] = "#{e}"
      settings.log.error("ERROR: #{e}")
      redirect "/manage_product"
    end
  end

  # Update product
  get '/update_product/:id' do
    protected!
    @id = params['id'].delete(':')
    protected_product!(@id)
    @product = Product.find(id: @id)
    if @product.nil?
      flash[:error] = "Το προϊόν δεν υπάρχει!"
      redirect '/panel'
    end
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
      settings.log.error("ERROR: #{e}")
      flash[:error] = "#{e}"
      redirect "/manage_product"
    rescue ArgumentError => e
      settings.log.error("ERROR: #{e}")
      flash[:error] = "#{e}"
      redirect "/manage_product"
    end
  end
end
