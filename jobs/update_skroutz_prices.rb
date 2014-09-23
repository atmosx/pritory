require_relative "#{File.expand_path File.dirname(__FILE__)}/../pritory"

class SkroutzWorker
  include Sidekiq::Worker

  # Sidekiq perform method
  # queries skroutz for any price change
  def perform

    # Logger class
    info_log = File.join(::File.dirname(::File.expand_path(__FILE__)),'..', 'log','info.log')
    @log = Logger.new(info_log)

    begin
      squick = Skroutz::Query.new
      list = Source.where('skroutz_id > 0')
      list.each do |entry|
        db_price = (((entry[:price].to_f)/100).to_f).to_s
        current_price = squick.skroutz_check entry[:skroutz_id]
        if db_price != current_price
          price = MyHelpers.euro_to_cents(current_price)
          product_id, skroutz_id, source = entry[:product_id], entry[:skroutz_id], entry[:source]
          Source.create(price: price, product_id: product_id, source: source, skroutz_id: skroutz_id)
          @log.info("Price update for #{Product.find(id: entry[:product_id]).name}")
          # else
          #   @log.info("Price for #{Product.find(id: entry[:product_id]).name} was not updated")
        end
      end
    rescue ArgumentError => e
      @log.error("ERROR (SkroutzWorker perform method): #{e}")
    end
  end
end

# Clockwork
include Clockwork

every(1.hour, 'perfoming prices update from skroutz') do
  SkroutzWorker.perform_async
end
