# encoding: utf-8
require 'sinatra'
require 'clockwork'
require 'sinatra/session'
require 'sinatra/partial'
require 'sinatra/flash'
require 'bluecloth'
require 'haml'
require 'openssl'
require 'redis'
require 'sidekiq'
require 'logger'

require_relative 'minify_resources'
require_relative 'mysecrets'
require_relative 'models/init'
require_relative 'routes/init'
require_relative 'helpers/init'

class Pritory < Sinatra::Base


  # Logger implementation for Sinatra
  ::Logger.class_eval { alias :write :'<<' }
  access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','access.log')
  access_logger = ::Logger.new(access_log)
  # info_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','info.log')
  # log = ::Logger.new(info_log)
  error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','error.log'),"a+")
  error_logger.sync = true

  configure do
    register Sinatra::Session
    register Sinatra::Partial
    register Sinatra::Flash

    # Make object accessible through routes - not sure if it's thread-safe e.g. better than $squick!
    set :squick, Skroutz::Query.new

    # Security measures for sessions	
    set :session_fail, '/login'
    set :session_secret, MySecrets::SESSION_SECRET

    # Setup environemnt 	
    set :environment, :development
    set :default_encoding, 'utf-8'
    set :dump_errors, true

    # Files and Folders	
    set :root, File.dirname(__FILE__)
    set :public_dir, "#{File.dirname(__FILE__)}/public"
    set :public_folder, 'public'

    # Dump Rack access logs to access_logger
    use ::Rack::CommonLogger, access_logger
  end

  configure :production do
    # Setup 'cache'
    set :cache_enabled, true
    set :cache_output_dir, "#{File.dirname(__FILE__)}/cache"
    set :cache_logging, true
    set :haml, { :ugly=>true }
    set :clean_trace, true
    set :css_files, :blob
    set :js_files,  :blob
    MinifyResources.minify_all
  end

  configure :development do
    # Faraday won't check SSL for ssl in 'development mode'
    OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
    
    set :css_files, MinifyResources::CSS_FILES
    set :js_files,  MinifyResources::JS_FILES
  end

  # set 'env' before every request and dump errors to error_logger
  before {
    env["rack.errors"] = error_logger
  }

  # Helpers magic!
  helpers do
    include Rack::Utils
    include Sidekiq::Worker
    alias_method :h, :escape_html
    
    # Login required
    def protected! 
      # halt [ 401, 'Not Authorized' ] unless session? 
      unless session?
        flash[:error] = '401 - Not Authorized'
        redirect '/'
      end
    end

    # Are you logged in?
    def protected?
      session? 
    end

    # When Page Not Found
    not_found do
      haml :not_found
    end
  end
end

# require_relative 'models/init'
# require_relative 'routes/init'
# require_relative 'helpers/init'
