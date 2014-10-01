web:         bundle exec thin start
sidekiq_web: bundle exec thin -R sidekiq.ru start -p 3001
sidekiq:     bundle exec sidekiq -r './jobs/update_skroutz_prices.rb'
clockwork:   bundle exec clockwork jobs/update_skroutz_prices.rb
