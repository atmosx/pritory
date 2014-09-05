require_relative "#{File.expand_path File.dirname(__FILE__)}/../pritory"

class SkroutzWorker
  include Sidekiq::Worker
  
  def perform
    squick = Skroutz::Query.new
    list = Source.where('skroutz_id > 0')
    list.each do |entry|
      id = entry[:skroutz_id]
      db_price = (((entry[:price].to_f)/100).to_f).to_s
      current_price = squick.skroutz_check id
      if db_price != current_price
        puts "price: #{current_price}"
        puts "db price: #{db_price}"
        entry.update(price: MyHelpers.euro_to_cents(current_price))
        puts "price updated!"
      else
        puts "price not updated"
      end
    end
  end
end
