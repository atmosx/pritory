# encoding: utf-8
require 'sinatra'
require 'haml'
require 'sinatra/session'
require 'sinatra/partial'
require 'sinatra/flash'
require 'bluecloth'
require 'haml'
require 'openssl'
# require 'logger'

require_relative 'minify_resources'
require_relative 'mysecrets'
require_relative 'models/init'
require_relative 'routes/init'
require_relative 'helpers/init'

class Pritory < Sinatra::Base

  # Faraday won't check SSL for now
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  # Log what happens
  # $log = Logger.new('log/output.log')

  configure do
    register Sinatra::Session
    register Sinatra::Partial
    register Sinatra::Flash

    # Make object accessible through routes
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

    # Skroutz Module (needs to be loaded by routes)
    module Skroutz
      class Query
        # OAuth2 client object
        def client
          client ||= OAuth2::Client.new(MySecrets::SKROUTZ_OAUTH_CID, MySecrets::SKROUTZ_OAUTH_PAS, site: 'https://skroutz.gr', authorize_url: "/oauth2/authorizations/new", token_url: "/oauth2/token", user_agent: 'pritory')
        end

        # Request token
        def get_token
          begin
            # Remember to define the scope here (e.g. 'public')
            t = client.client_credentials.get_token(scope: 'public') 
          rescue OAuth2::Error => e
            e.response.status == 404 ? "Not Found: 404" : e
          end
        end

        # Skroutz search product category (step 1)
        def query_skroutz keyword
          begin
            raise ArgumentError.new("Keyword is too small!") if keyword.length < 3
            token =  get_token.token
            con = Faraday.new
            con.params = {oauth_token: token}
            con.headers = {user_agent: 'pritory'}
            con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
            r1 = con.get "http://api.skroutz.gr/api/search?q=#{keyword}"
            JSON.parse(r1.body)
          rescue ArgumentError => e
            puts e
          rescue OAuth2::Error => e
            puts "\nResponse headers: #{e.response.headers}"
          end
        end

        # Search for categories (step 2)
        def query_skroutz2 id, name
          begin
            token =  get_token.token
            con = Faraday.new
            con.params = {oauth_token: token}
            con.headers = {user_agent: 'pritory'}
            con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
            r1 = con.get "http://api.skroutz.gr/api/categories/#{id}/skus?q=#{name}"
            JSON.parse(r1.body)
          rescue ArgumentError => e
            puts e
          rescue OAuth2::Error => e
            puts "\nResponse headers: #{e.response.headers}"
          end
        end

        def query_skroutz3 id
          begin
            token =  get_token.token
            con = Faraday.new
            con.params = {oauth_token: token}
            con.headers = {user_agent: 'pritory'}
            con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
            r1 = con.get "http://api.skroutz.gr/api/skus/#{id}/products"
            JSON.parse(r1.body)
          rescue ArgumentError => e
            puts e
          rescue OAuth2::Error => e
            puts "\nResponse headers: #{e.response.headers}"
          end
        end
      end
    end
    
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

  # Define 'squick', accessible by routes
  @squick ||= Skroutz::Query.new
end

# require_relative 'models/init'
# require_relative 'routes/init'
# require_relative 'helpers/init'
