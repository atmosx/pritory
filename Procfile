web:         thin start
redis:       redis-server
sidekiq_web: thin -R sidekiq.ru start -p 3001
sidekiq:     sidekiq -r './jobs/update_skroutz_prices.rb'
clockwork:   clockwork jobs/update_skroutz_prices.rb
