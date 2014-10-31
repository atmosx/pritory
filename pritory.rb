# encoding: utf-8
require 'sinatra'
require 'sinatra/cache'
require 'sinatra/session'
require 'sinatra/partial'
require 'sinatra/flash'
require 'sinatra/sequel'
require 'fileutils'
require 'clockwork'
require 'bluecloth'
require 'mini_magick'
require 'haml'
require 'chartkick'
require 'openssl'
require 'redis'
require 'sidekiq'
require 'logger'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'pony'
require 'sqlite3'

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
  info_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','info.log')

  error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','error.log'),"a+")
  error_logger.sync = true

  configure do
    register(Sinatra::Cache)
    register Sinatra::Session
    register Sinatra::Partial
    register Sinatra::Flash

    # Make object accessible through routes - not sure if it's thread-safe e.g. better than $squick!
    set :squick, Skroutz::Query.new
    set :log, Logger.new(info_log)

    # Security measures for sessions	
    set :session_fail, '/login'
    set :session_secret, MySecrets::SESSION_SECRET

    # Setup environemnt 	
    set :environment, MySecrets::ENVIR.to_sym
    set :default_encoding, 'utf-8'
    set :dump_errors, true

    # Files and Folders	
    set :root, File.dirname(__FILE__)
    set :public_dir, "#{File.dirname(__FILE__)}/public"
    set :public_folder, 'public'

    # Dump Rack access logs to access_logger use ::Rack::CommonLogger, access_logger

    # Locale Load
    # I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = Dir[File.join(settings.root, 'locales', '*.yml')]
    # I18n.backend.load_translations
    I18n.config.enforce_available_locales = true
    I18n.default_locale = 'en'
  end

  configure :production do
    # Setup 'cache'
    set :cache_enabled, true
    set :cache_output_dir, "#{File.dirname(__FILE__)}/cache"
    set :cache_logging, true
    set :haml, { ugly: true }
    set :clean_trace, true
    set :css_files, :blob
    set :js_files,  :blob
    MinifyResources.minify_all
  end

  configure :development do
    # Faraday won't check SSL for ssl in 'development mode'
    # OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
    set :cache_enabled, false
    set :cache_output_dir, "#{File.dirname(__FILE__)}/cache"
    set :cache_logging, false

    set :css_files, MinifyResources::CSS_FILES
    set :js_files,  MinifyResources::JS_FILES
  end

  configure :test do
    set :database, 'sqlite3::memory:'
  end

  # set 'env' before every request and dump errors to error_logger
  before { env["rack.errors"] = error_logger }

  # Helpers magic!
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    # Just a simple alias
    def t(*args)
      I18n.t(*args, locale: session[:locale])
    end	 

    # Load active users
    def load_active_user
      User.first(username: session['name'])
    end

    # Login required
    # Halt [ 401, 'Not Authorized' ] unless session? 
    def protected 
      unless session?
        flash[:error] = '401 - Not Authorized'
        redirect '/'
      end
    end

    # Are you logged in?
    def protected?
      session? 
    end

    # Accessible source only by user who source belongs to
    def protected_source(id)
      begin
        unless User.find(id: Source.find(id: id).product.user_id).username == session['name'] 
          settings.log.error("[SECURITY]: user #{sesion['name']} tried to access foreign source with id: #{id}")
          flash[:error] = 'ΠΡΟΣΟΧΗ: Η πηγή που ανήκει σε άλλο χρήστη!!!!' 
          redirect '/panel'
        end
      rescue NoMethodError => e
        flash[:error] = 'Η πηγή που ψάχνετε δεν υπάρχει!'  
        settings.log.error("ERROR (protected_source - NoMethodError): #{e}")
        redirect '/panel'
      end
    end

    # Accessible product only by user who product belongs to
    def protected_product(id)
      begin
        unless User.find(id: Product.find(id: id).user_id).username == session['name'] 
          settings.log.error("[SECURITY]: user #{session['name']} tried to access foreign product with id: #{id}")
          flash[:error] = 'ΠΡΟΣΟΧΗ: Το προϊόν ανήκει σε άλλο χρήστη!!!!'  
          redirect '/panel'
        end
      rescue NoMethodError => e
        flash[:error] = 'Το προϊόν που ψάχνετε δεν υπάρχει!'  
        settings.log.error("ERROR (protected_product - NoMethodError): #{e}")
        redirect '/panel'
      end
    end

    # i18n - Locale setup in session
    before do
      session[:locale] = params[:locale] if params[:locale] #the r18n system will load it automatically
      session[:locale] = 'en' if params[:locale] == nil
      load_active_user  # pull user from database or whatever based on session info.
      session[:locale] = @active_user.locale if @active_user != nil && session[:locale] == nil
    end

    # When Page Not Found
    not_found do
      haml :not_found
    end
  end
end
# add this
