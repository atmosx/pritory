redis:       redis-server
sidekiq:     bundle exec sidekiq -r './jobs/update_skroutz_prices.rb'
sidekiq_web: bundle exec thin -R sidekiq.ru start -p 3001
web:         bundle exec thin start
clockwork:   bundle exec clockwork jobs/update_skroutz_prices.rb
