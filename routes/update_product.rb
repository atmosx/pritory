
class Pritory < Sinatra::Base

  # Update product
  get '/update_product/:id' do

    protected

    @id = params['id'].delete(':')
    protected_product(@id)
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
      # Retrieving tags to create an array here. This can be optimized!
      @tags = @product.tags.map{|x| x.name}
      haml :update_product
    rescue => e
      flash[:error] = "#{e}"
      settings.log.error("ERROR: (routes/product.rb:121): #{e}")
      redirect "/add_product"
    end
  end

  # Post product
  post '/update_product' do

    protected

    img = params['image']
    a = Product.find(id: params['id'])
    user = User.first(username: session['name'])
    store = user.setting.storename
    begin
      a.update(
        vat_category: params['vat_category'].to_f,
        name: params['name'], 
        barcode: params['barcode'], 
        cost: MyHelpers.euro_to_cents(params['cost']), 
        notes: params['comment']
      )

      # Update dates
      old_tags = a.tags.map{|x| x.name}
      new_tags = params['tags'].split(',')
      if old_tags != new_tags
        old_tags.each do |e|
          unless new_tags.include? e
            a.remove_tag(Tag.find(name: e).id)
          end
        end

        new_tags.each do |e|
          a.add_tag(name: e.strip)
        end
      end

      # find source_id
      s = a.sources_dataset.where(name: user.setting.storename).first
      s.update(
        price: MyHelpers.euro_to_cents(params['price'])
      )
      if img
        filename = params['image'][:filename]
        images_dir = Dir["public/images/users/#{user.id}/products/"]

        # Check for overwrites - DOESNT WORK
        if images_dir.include? "#{images_dir}/#{filename}"
          raise ArgumentError.new("Παρακαλώ αλλάξτε όνομα στην εικόνα!") 
        end
        image_path = "#{images_dir[0]}/#{params['image'][:filename]}"
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
      redirect "/add_product"
    rescue ArgumentError => e
      settings.log.error("ERROR: #{e}")
      flash[:error] = "#{e}"
      redirect "/add_product"
    end
  end
end
