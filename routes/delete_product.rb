class Pritory < Sinatra::Base
  # Delete Product
    get '/delete_product/:id' do
      protected

      id = params['id'].delete(':')
      protected_product(id)
      begin

        # Find product
        product = Product.find(id: id)

        # Load image path
        img_path = "/public/users/#{product.user_id}/products/#{product.img_url}"
        
        # Remove and delete tags and sources
        tags = product.tags
        sources = product.sources
        product.remove_all_tags
        product.remove_all_sources
        tags.each {|tag| tag.delete}
        sources.each {|source| source.delete}

        # remove image if exists
        FileUtils.rm(img_path) if File.exist? img_path

        # delete product from database
        product.delete
        flash[:success] = "#{t 'product_delete_success'}"
        redirect "/panel"
      rescue => e
        flash[:error] = "#{e}"
        settings.log.error("ERROR: #{e}")
        redirect "/add_product"
      end
    end
end
