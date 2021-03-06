# encoding: utf-8
class Pritory < Sinatra::Base
  # User panel
  get "/panel" do
    protected

    @user = User.first(username: session['name'])
    @products = @user.products
    @avg_margin = @avg_markup = 0
    unless @products.empty?
      margin_list = []
      markup_list = []
      percent_list = []
      @products.each do |p|
        cost = MyHelpers.numeric_to_float(p[:cost])
        sorted = p.sources_dataset.where(name: @user.setting.storename).sort_by {|h| h[:created_at]}
        # Take the most recent price entry
        price = MyHelpers.numeric_no_vat(sorted.last[:price], p.vat_category)
        percentage_hash = MyHelpers.price_diff(p[:id], @user.setting.storename)
        markup_list << (price - cost).round(2) 
        margin_list << ((price - cost)/price)
        percent_list << percentage_hash[:diff_percentage].round(2)
      end
      # Get AVG from arrays for markup/margin. 
      # See here for neat ways: http://stackoverflow.com/questions/1341271/how-do-i-create-an-average-from-a-ruby-array
      @avg_markup = "#{(markup_list.instance_eval { reduce(:+) / size.to_f }).round(2).to_s} #{@user.setting.currency}"
      @avg_margin = "#{(margin_list.instance_eval { reduce(:+) / size.to_f } * 100).round(2)} %"
      @avg_percent = "#{(percent_list.instance_eval {reduce(:+)/ size.to_f}).round(2) * 100} %"
    end
    haml :panel
  end
end
