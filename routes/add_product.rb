class Pritory < Sinatra::Base

  # Add product
  get '/add_product' do
    protected!
    user = User.first(username: session['name'])
    @vats = Vat.where(country: user.setting.country).select_map(:vat)
    @products = user.products
    haml :manage_product
  end

  # Post product
  post '/add_product' do
    protected!
    user = User.first(username: session['name'])
    img = params['image']
    if params['name'].empty?
      flash[:error] = "Δεν μπορεί να καταχωρηθεί προϊόν χωρίς όνομα!"
      redirect '/panel'
    end
    if params['tags'].empty?
      flash[:error] = "Δεν γίνεται το προϊόν να μην έχει τουλάχιστον 1 ετικέτα!"
      redirect '/panel'
    end
    begin
      a = Product.create(
        user_id: user.id, 
        vat_category: params['vat_category'].to_f,
        name: params['name'], 
        barcode: params['barcode'], 
        cost: MyHelpers.euro_to_cents(params['cost']), 
        notes: params['comment'],
        created_at: TZInfo::Timezone.get('Europe/Athens').now
      )

      # Create and/or associate tags to products
      params['tags'].split(',').each do |t|
        if Tag.find(tag_name: t).nil?
          b = Tag.create(tag_name: t)
          Ptag.create(product_id: a.id, tag_id: b.id)
        else
          Ptag.create(product_id: a.id, tag_id: Tag.find(tag_name: t).id)
        end
      end

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
      if params['squick'] == 'yes'
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
end