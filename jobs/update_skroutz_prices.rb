require_relative "#{File.expand_path File.dirname(__FILE__)}/../pritory"

class SkroutzWorker
  include Sidekiq::Worker

  # Sidekiq perform method
  # queries skroutz for any price change
  def perform
    begin
      squick = Skroutz::Query.new
      list = Source.where('skroutz_id > 0')
      list.each do |entry|
        db_price = (((entry[:price].to_f)/100).to_f).to_s
        current_price = squick.skroutz_check entry[:skroutz_id]
        if db_price != current_price
          price = MyHelpers.euro_to_cents(current_price)
          pid, skroutz_id, source = entry[:product_id], entry[:skroutz_id], entry[:source]
          Source.create(price: price, product_id: product_id, source: source, skroutz_id: skroutz_id)
          puts "price updated!"
        else
          puts "price not updated"
        end
      end
    rescue ArgumentError => e
      puts "An error has occured: #{e}"
    end
  end
end

# Clockwork
include Clockwork

every(1.hour, 'perfoming prices update from skroutz') do
  SkroutzWorker.perform_async
end

# x = SkroutzWorker.new
# x.perform
