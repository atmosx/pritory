redis:       redis-server
sidekiq:     bundle exec sidekiq -r './workers/skroutz_worker.rb'
sidekiq_web: bundle exec thin -R sidekiq.ru start -p 3001
web:         bundle exec thin start
clockwork:   bundle exec clockwork clock.rb
