require_relative "#{File.expand_path File.dirname(__FILE__)}/../pritory"

class SkroutzWorker
  include Sidekiq::Worker
  
  # Sidekiq perform method
  # queries skroutz for any price change
  def perform
    squick = Skroutz::Query.new
    puts Skroutz::Query.counter
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


# Clockwork
include Clockwork

# every(1.hour, 'perfoming prices update from skroutz') do
every(7.seconds, 'perfoming prices update from skroutz') do
  SkroutzWorker.perform_async
end
