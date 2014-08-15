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
      @product = Product.find(id: id)
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
        name: params['name'], 
        barcode: params['barcode'], 
        description: params['description'], 
        cost: MyHelpers.euro_to_cents(params['cost']), 
        notes: params['comment']
      )
      if img
        # "9850780-orig.jpg"
        filename = params['product_image'][:filename]
        # ["public/images/9850780-orig.jpg", "public/images/apple-touch-icon-114x114.png", "public/images/apple-touch-icon-72x72.png", "public/images/apple-touch-icon.png", "public/images/default.jpg", "public/images/favicon.ico"]
        images = Dir['public/images/*']

        # Check for overwrites - DOESNT WORK
        if images.include? "public/images/#{filename}"
          raise ArgumentError.new("Παρακαλώ αλλάξτε όνομα στην εικόνα!") 
        end

        File.open('public/images/' + params['product_image'][:filename], "w") do |f|
           f.write(params['product_image'][:tempfile].read)
        end
        Product.update(img_url: params['product_image'][:filename])
      end
      flash[:result] = "Το προϊόν προστέθηκε στην βάση δεδομένων"
      redirect '/manage_product'
    rescue Sequel::Error => e
      flash[:error] = "#{e}"
    rescue ArgumentError => e
      flash[:error] = "#{e}"
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
      flash[:result] = "Η πηγή καταχωρήθηκε στην βάση δεδομένων"
      redirect '/manage_source'
    rescue Sequel::Error => e
      flash[:error] = "#{e}"
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
