# encoding: utf-8
class Pritory < Sinatra::Base

  # User panel
  get "/panel" do
    protected!
    @user = User.first(username: session['name'])
    @products = @user.products
    @avg_margin = @avg_markup = 0
    unless @products.empty?
      margin_list = []
      markup_list = []
      @products.each do |p|
        cost = MyHelpers.numeric_to_float(p[:cost])
        sorted = p.sources_dataset.where(source: @user.setting.storename).sort_by {|h| h[:created_at]}
        # Take the most recent price entry
        price = MyHelpers.numeric_no_vat(sorted.last[:price], p.vat_category)
        markup_list << (price - cost).round(2) 
        margin_list << ((price - cost)/price)
      end
      # Get AVG from arrays for markup/margin. 
      # See here for neat ways: http://stackoverflow.com/questions/1341271/how-do-i-create-an-average-from-a-ruby-array
      @avg_markup = "#{(markup_list.instance_eval { reduce(:+) / size.to_f }).round(2).to_s.gsub('.',',')} €"
      @avg_margin = "#{(margin_list.instance_eval { reduce(:+) / size.to_f } * 100).round(2).to_s.gsub('.',',')} %"
    end
    haml :panel
  end

  # Add product
  get '/manage_product' do
    protected!
    user = User.first(username: session['name'])
    @vats = Vat.where(country: user.setting.country).select_map(:vat)
    @products = user.products
    haml :manage_product
  end

  # View Product and related info
  # That's the main panel
  get '/view_product/:id' do
    protected!
    id = params['id'].delete(':')
    protected_product!(id)
    @user = User.first(username: session['name'])
    @store = @user.setting.storename
    @product = Product.find(id: id)
    if @product.nil?
      flash[:error] = "Το προϊόν που ψάχνετε δεν υπάρχει!"
      settings.log.warn("[SECURITY] user #{@user} tried to access product that doesn't exist, with id #{id}!")
      redirect '/panel'
    end
    # MAJOR CLEAN UP NEEDED
    @cost = MyHelpers.cents_to_euro(@product.cost)
    # Sort prices for products on our store. Display the latest is '.last'
    sorted = @product.sources_dataset.where(source: @store).sort_by {|h| h[:created_at]}
    @price = MyHelpers.cents_to_euro(sorted.last[:price])
    @price_without_vat = MyHelpers.cents_to_euro(sorted.last[:price] / ((@product.vat_category/100)+1))
    list_of_sources = []
    @product.sources.each {|e| list_of_sources << e[:source] unless list_of_sources.include? e[:source]}
    @latest_prices = [] 
    list_of_sources.each do |s|
      sorted = @product.sources_dataset.where(source: s).sort_by {|h| h[:created_at]}
      @latest_prices << sorted.last
    end
   # Margin and MarkUp explained simply http://www.qwerty.gr/howto/margin-vs-markup
   # current_price_no_vat = MyHelpers.numeric_no_vat(sorted.last[:price].to_f, @product.vat_category).to_f
   current_price_no_vat = @price_without_vat.split(' ')[0].sub(',','.').to_f
   cost = MyHelpers.numeric_to_float(@product.cost)
   @markup = "#{(current_price_no_vat - cost).round(2).to_s.sub('.',',')} €"
   # @margin = "#{(((current_price_no_vat - cost)/ current_price_no_vat) * 100).round(2)} %"
   @margin = "#{current_price_no_vat.to_s.sub('.',',')} %"
   @data = MyHelpers.make_graph(@product.sources)
   haml :view_product
  end

  # Post product
  post '/manage_product' do
    protected!
    user = User.first(username: session['name'])
    img = params['image']
    if params['name'].empty?
      flash[:error] = "Δεν μπορεί να καταχωρηθεί προϊόν χωρίς όνομα!"
      redirect '/panel'
    end
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
        source: user.setting.storename,
        price: MyHelpers.euro_to_cents(params['price']),
        created_at: TZInfo::Timezone.get('Europe/Athens').now
      )
      if img
        filename = params['image'][:filename]
        images_dir = "public/images/users/#{user.id}/products/"
        FileUtils::mkdir_p images_dir unless File.directory?(images_dir)

        # Check for overwrites - DOESNT WORK
        #
        # if images.include? "public/images/#{user.id}/products/#{filename}"
        #   raise ArgumentError.new("Παρακαλώ αλλάξτε όνομα στην εικόνα!") 
        # end

        image_path = images_dir + params['image'][:filename]
        File.open(image_path, "w") do |f|
          f.write(params['image'][:tempfile].read)
        end

        # Convert all images to 150px height for the time being
        # NOTE: Fore more complex processing try: https://github.com/markevans/dragonfly
        # I believe this processing is considerably easy/fast even for underpowered servers,
        # If further processing on images is needed it can be using sidekiq_async in the background.
        process_image = MiniMagick::Image.open(image_path)
        process_image.resize "150x150"
        process_image.write image_path
        a.update(img_url: params['image'][:filename])
      end
      p s = params['squick']
      if s == 'yes'
        redirect "/skroutz_add/:#{params['name']}" 
      else
        redirect "/panel"
        flash[:success] = "Το προϊόν προστέθηκε στην βάση δεδομένων"
      end
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
      product.sources.each {|s| s.delete}
      img_path = "/public/users/#{product.user_id}/products/#{product.img_url}"
      FileUtils.rm(img_path) if File.exist? img_path
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
    begin
      @product = Product.find(id: @id)
      if @product.nil?
        flash[:error] = "Το προϊόν δεν υπάρχει!"
        redirect '/panel'
      end
      @cost = MyHelpers.cents_to_euro(@product.cost)
      @price = MyHelpers.cents_to_euro(@product.sources[0][:price])
      margin = (@product.sources[0][:price] - @product.cost)/@product.sources[0][:price]
      @markup = MyHelpers.cents_to_euro(@product.sources[0][:price] - @product.cost)
      @margin = MyHelpers.numeric_to_percentage(margin)
      user = User.first(username: session['name'])
      img = params['image']
      haml :update_product
    rescue => e
      flash[:error] = "#{e}"
      settings.log.error("ERROR: (routes/product.rb:121): #{e}")
      redirect "/manage_product"
    end
  end

  # Post product
  post '/update_product' do
    protected!
    img = params['image']
    a = Product.find(id: params['id'].to_i)
    user = User.first(username: session['name'])
    store = user.setting.storename
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
      # NOTE: We could use a more elegant solution like: a.sources_dataset.where(store: "Metropolis Pharmacy")
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
        images_dir = Dir["public/images/users/#{@user.id}/products/"]

        # Check for overwrites - DOESNT WORK
        if images_dir.include? "#{images_dir}/#{filename}"
          raise ArgumentError.new("Παρακαλώ αλλάξτε όνομα στην εικόνα!") 
        end
        image_path = images_dir + params['image'][:filename]
        File.open(image_path, "w") do |f|
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
