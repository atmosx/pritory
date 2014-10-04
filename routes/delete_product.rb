class Pritory < Sinatra::Base
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
end