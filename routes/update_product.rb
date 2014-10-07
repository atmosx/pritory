
class Pritory < Sinatra::Base

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
      # Retrieving tags to create an array here. This can be optimized!
      tags_array = []
      tags = @product.ptags.each {|x| tags_array << Tag.find(id: x.tag_id).tag_name}
      @tags = tags_array
      haml :update_product
    rescue => e
      flash[:error] = "#{e}"
      settings.log.error("ERROR: (routes/product.rb:121): #{e}")
      redirect "/add_product"
    end
  end

  # Post product
  post '/update_product' do
    protected!
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
      tags_array = []
      a.ptags.each {|x| tags_array << Tag.find(id: x.tag_id).tag_name}
      old_tags = tags_array
      new_tags = params['tags'].split(',')

      # Optimize THIS plz!
      # Remove old tags
      unless old_tags.sort == new_tags.sort 
        # Delete only ptag entries. 
        old_tags.each do |t|
          Tag.find(tag_name: t).each {|tag| Ptag.delete(tag.ptag[0].id)}
        end
        # Write a 'job' that will remove all tags with no ptag association!

        # Add new tags
        new_tags.each do |t|
          if Tag.find(tag_name: t).nil?
            b = Tag.create(tag_name: t)
            Ptag.create(product_id: a.id, tag_id: b.id)
          else
            Ptag.create(product_id: a.id, tag_id: Tag.find(tag_name: t).id)
          end
        end
      end
      # find source_id
      # NOTE: We could use a more elegant solution like: a.sources_dataset.where(store: "Metropolis Pharmacy")
      sid = nil
      a.sources.each do |entry|
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
