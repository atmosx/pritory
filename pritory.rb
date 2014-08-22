# encoding: utf-8
require 'sinatra'
require 'haml'
require 'oauth2'
require 'json'
require 'sinatra/session'
require 'sinatra/partial'
require 'sinatra/flash'
require 'bluecloth'
require 'haml'
require 'logger'
require 'openssl'

require_relative 'minify_resources'
require_relative 'mysecrets'

class Pritory < Sinatra::Base
  # enable :sessions

  # Faraday won't check SSL for now
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  # Log what happens
  $log = Logger.new('log/output.log')

  configure do
    register Sinatra::Session
    register Sinatra::Partial
    register Sinatra::Flash

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
    set :css_files, MinifyResources::CSS_FILES
    set :js_files,  MinifyResources::JS_FILES
  end

  # Helpers magic!
  helpers do
    include Rack::Utils
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

require_relative 'models/init'
require_relative 'routes/init'
require_relative 'helpers/init'
