# encoding: utf-8
class Pritory < Sinatra::Base
  # User tags
  get "/tags/:tag" do
    protected

    @tag = params['tag'].delete(':')
    @user = User.first(username: session['name'])
    @products = []
    Tag.where(name: @tag).each do |e|
      entry = e.products[0]
      sorted = e.products[0].sources_dataset.where(name: @user.setting.storename).sort_by {|h| h[:created_at]}
      if @user.id == entry.user_id
        entry.values[:most_recent_price] = sorted.last[:price]
        @products << entry.values
      end
    end
    
    unless @products.nil?
      markup_list = margin_list = []
      @products.each do |entry|
        cost = MyHelpers.numeric_to_float(entry[:cost])
        # Take the most recent price entry
        price = MyHelpers.numeric_no_vat(entry[:most_recent_price], entry[:vat_category])
        markup_list << (price - cost).round(2) 
        margin_list << ((price - cost)/price)
      end
      # Get AVG from arrays for markup/margin. 
      # See here for neat ways: http://stackoverflow.com/questions/1341271/how-do-i-create-an-average-from-a-ruby-array
      @avg_markup = "#{(markup_list.instance_eval { reduce(:+) / size.to_f }).round(2).to_s.gsub('.',',')} €"
      @avg_margin = "#{(margin_list.instance_eval { reduce(:+) / size.to_f } * 100).round(2).to_s.gsub('.',',')} %"
      haml :tags
    else
      'nothing'
    end
  end
end
