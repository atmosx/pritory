# Pritory dev Guardfile
# More info at https://github.com/guard/guard#readme
notification :growl

guard :rspec, cmd: 'bundle exec rspec' do
  watch('pritory.rb')
  watch(%r{^spec/.+_spec\.rb$})
  %w{ models helpers routes}.each do |k|
    watch(%r{^(#{k})\/.+\.rb$}) { |m| "spec/#{k}_spec.rb"}
  end

  # Capybara features specs
  watch(%r{^views/(.+)/.*\.haml$}) { |m| "spec/features/#{m[1]}_spec.rb" }
end

guard 'spork', :rspec_env => { 'ENV' => 'test' } do
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
end

# Fire up your server and switch to foreman?!
guard 'shotgun', :server => 'thin', port: '3000' do
  watch %r{.*\.(rb|haml|css|yml)}
  watch 'config.ru'
end
