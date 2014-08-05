# encoding: utf-8
class Pritory < Sinatra::Base

  # User logged in
  get "/panel" do
    protected!
    user = User.first(username: session['name'])
    @products = user.products
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
    begin
      Product.create(
        user_id: user.id, 
        category: params['category'],
        product_name: params['name'], 
        product_barcode: params['barcode'], 
        product_description: params['description'] 
      )
      flash[:result] = "Το προϊόν προστέθηκε στην βάση δεδομένων"
      redirect '/manage_product'
    rescue Sequel::Error => e
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
    pro = Product.find(product_name: params['product_name'])
    price_in_cents = MyHelpers.euro_to_cents(params['price'].to_f)
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

  # Delete product
  get '/del/:id' do
    protected!
    id = params['id'].delete(':')
    begin
      Source.find(id: id).delete
      flash[:success] = "Η πηγή έχει διαγραφεί με επιτυχία από την βάση δεδομένων!"
      redirect "/panel"
    rescue => e
      flash[:error] = "#{e}"
    end
  end
  
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
