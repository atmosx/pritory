redis:       redis-server
sidekiq:     bundle exec sidekiq -r './work.rb'
sidekiq_web: bundle exec thin -R sidekiq.ru start -p 3001
web:         bundle exec thin start
clockwork:   bundle exec clockwork work.rb
