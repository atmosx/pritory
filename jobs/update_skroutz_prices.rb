require_relative "#{File.expand_path File.dirname(__FILE__)}/../pritory"

class SkroutzWorker
  include Sidekiq::Worker

  # Sidekiq perform method
  # queries skroutz for any price change
  def perform
    # Logger class
    info_log = File.join(::File.dirname(::File.expand_path(__FILE__)),'..', 'log','info.log')
    @log = Logger.new(info_log)
    # Set variables
    ids, sid = [], []
    Source.where('skroutz_id > 0').each {|e| sid << e.values[:skroutz_id] unless sid.include?(e.values[:skroutz_id])}
    sid.each {|id| sorted = Source.where(skroutz_id: id).sort_by {|h| h[:created_at]};ids << sorted.last.id}
    squick = Skroutz::Query.new
    ids.each do |id|
      tries ||= 3
      begin
        entry = Source.find(id: id)
        @log.info("Checking update for #{Product.find(id: entry[:product_id]).name}")
        db_price = (((entry[:price].to_f)/100).to_f).to_s
        current_price = squick.skroutz_check(entry[:skroutz_id])
        # Here we need to adjust current price to .2 decimal points, otherwise it updates the price at every pull
        if db_price != current_price
          @log.debug("Price difference: #{db_price} - (#{db_price.class}) - different than #{current_price} - (#{current_price.class})")
          price = MyHelpers.euro_to_cents(current_price)
          product_id, skroutz_id, source = entry[:product_id], entry[:skroutz_id], entry[:name]
          Source.create(price: price, product_id: product_id, name: source, skroutz_id: skroutz_id, created_at: TZInfo::Timezone.get('Europe/Athens').now)
          @log.info("Price update for #{Product.find(id: entry[:product_id]).name}")
        end
      rescue Faraday::ConnectionFailed => e
        tries -= 1
        if tries > 0
          retry
        else
          @log.info("Connection failed: #{e}")
        end
      end
    end
  end
end

# Clockwork
include Clockwork

every(1.hour, 'perfoming prices update from skroutz') do
  SkroutzWorker.perform_async
end
