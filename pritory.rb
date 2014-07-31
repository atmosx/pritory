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

    # Skroytz OAuth2
    def client
      client ||= OAuth2::Client.new(MySecrets::SKROUTZ_OAUTH_CID, MySecrets::SKROUTZ_OAUTH_PAS, {
        site: 'https://skroutz.gr', 
        authorize_url: "/oauth2/authorizations/new", 
        token_url: "/oauth2/token",
        user_agent: 'pritory testing'
      })
    end
  end

  # http://developer.skroutz.gr/authentication/permissions/
  get '/auth' do
    $log.info("auth accessed 1!")
    redirect client.auth_code.authorize_url(redirect_uri: redirect_uri, scope: 'public', grant_type: "client_credentials")
    $log.info("redirect done!")
  end

  get '/callback' do
    access_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
    session[:access_token] = access_token.token
    @message = "Successfully authenticated with the server"
    @access_token = session[:access_token]
    $log.info("#{@message}: #{@access_token}")

    # parsed is a handy method on an OAuth2::Response object that will 
    # intelligently try and parse the response.body
    # @email = access_token.get('https://www.googleapis.com/userinfo/email?alt=json').parsed
    haml :success
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = '/callback'
    uri.query = nil
    uri.to_s
  end 

  # When Page Not Found
  not_found do
    haml :not_found
  end

end

require_relative 'helpers/init'
require_relative 'models/init'
require_relative 'routes/init'
