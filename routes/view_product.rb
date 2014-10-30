class Pritory < Sinatra::Base
  # View Product and related info
  # That's the main panel
  get '/view_product/:id' do
    protected
    
    id = params['id'].delete(':')
    protected_product(id)
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
    sorted = @product.sources_dataset.where(name: @store).sort_by {|h| h[:created_at]}
    @price = MyHelpers.cents_to_euro(sorted.last[:price])
    @price_without_vat = MyHelpers.cents_to_euro(sorted.last[:price] / ((@product.vat_category/100)+1))
    list_of_sources = []
    @product.sources.each {|e| list_of_sources << e[:name] unless list_of_sources.include? e[:name]}
    @latest_prices = [] 
    list_of_sources.each do |s|
      sorted = @product.sources_dataset.where(name: s).sort_by {|h| h[:created_at]}
      @latest_prices << sorted.last
    end
    # Margin and MarkUp explained simply http://www.qwerty.gr/howto/margin-vs-markup
    # current_price_no_vat = MyHelpers.numeric_no_vat(sorted.last[:price].to_f, @product.vat_category).to_f
    current_price_no_vat = @price_without_vat.split(' ')[0].sub(',','.').to_f
    cost = MyHelpers.numeric_to_float(@product.cost)
    @markup = "#{(current_price_no_vat - cost).round(2).to_s.sub('.',',')}"
    # @margin = "#{(((current_price_no_vat - cost)/ current_price_no_vat) * 100).round(2)} %"
    @margin = "#{current_price_no_vat.to_s.sub('.',',')} %"
    @data = MyHelpers.make_graph(@product.sources)
    # Retrieving tags in array form
    @tags = @product.tags.map{ |x| x.name }
    column_graph = []
    list_of_prices = @latest_prices.map { |e| MyHelpers.numeric_to_float(e[:price]) }
    @average_market_price = (list_of_prices.reduce(:+).to_f / list_of_prices.size).round(2)
    @latest_prices.each do |e|
      price = MyHelpers.numeric_to_float e[:price]
      column_graph << [e[:name],  price]
    end
    @column_graph = column_graph
    haml :view_product
  end
end
