#!/usr/bin/env ruby

require 'oauth2'
require 'net/http'
require 'json'
require 'faraday'
require 'sidekiq'
require 'logger'
require_relative "#{File.expand_path File.dirname(__FILE__)}/../mysecrets"

# Handle Sroutz API Calls
module Skroutz
  class Query
    
    # Logger class
    def initialize 
      info_log = File.join(::File.dirname(::File.expand_path(__FILE__)),'..', 'log','info.log')
      @log = Logger.new(info_log)
    end

    # Check Skrouz API limit (max 100 req per minute)
    def check_limit response
      if response.headers['x-ratelimit-remaining'].to_i <= 1
        wait = (Time.at(response.headers['x-ratelimit-reset'].to_i).utc - Time.now.utc).to_i + 1
        @log.info("Skroutz API Limit reached, waiting #{wait} seconds for reset!") 
        sleep(wait)
      else
         @log.info("API limit is #{response.headers['x-ratelimit-remaining']}")
      end
    end

    # OAuth2 client object
    def client
      begin
        client ||= OAuth2::Client.new(MySecrets::SKROUTZ_OAUTH_CID, MySecrets::SKROUTZ_OAUTH_PAS, site: 'https://skroutz.gr', authorize_url: "/oauth2/authorizations/new", token_url: "/oauth2/token", user_agent: 'pritory', ssl:{ca_file: MySecrets::CERTFILE})
      rescue OAuth2::Error => e
        @log.error("Skroutz OAuth2 error: #{e}")
      end
    end

    # Request token
    def get_token
      begin
        # Remember to define the scope here (e.g. 'public')
        t = client.client_credentials.get_token(scope: 'public') 
      rescue OAuth2::Error => e
        e.response.status == 404 ? @log.error("URL Not Found: 404") : @log.error("OAuth2 (get_token) error: #{e}")
      end
    end

    # Skroutz search product category (step 1)
    def query_skroutz keyword
      begin
        token =  get_token.token
        con = Faraday::Connection.new(ssl:{ca_file: MySecrets::CERTFILE})
        con.params = {oauth_token: token}
        con.headers = {user_agent: 'pritory'}
        con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
        r1 = con.get "http://api.skroutz.gr/api/search?q=#{keyword}"
        return JSON.parse(r1.body)
      rescue OAuth2::Error => e
        @log.error "\nResponse headers (query_skroutz): #{e.response.headers}"
        @log.error "\nError (query_skroutz): #{e}"
        return e.class
      end
      # check limit after execution ended
      check_limit r1
    end

    # Search for categories (step 2)
    def query_skroutz2 id, name
      begin
        token =  get_token.token
        con = Faraday::Connection.new(ssl:{ca_file: MySecrets::CERTFILE})
        con.params = {oauth_token: token}
        con.headers = {user_agent: 'pritory'}
        con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
        r1 = con.get "http://api.skroutz.gr/api/categories/#{id}/skus?q=#{name}"
        return JSON.parse(r1.body)
      rescue ArgumentError => e
        @log.error("Error (query_skroutz2): #{e}")
      rescue OAuth2::Error => e
        @log.error("Response headers: #{e.response.headers}")
        @log.error("Error (query_skroutz2): #{e}")
      end
      check_limit r1
    end

    # Search the product (step 3)
    def query_skroutz3 id
      begin
        token =  get_token.token
        con = Faraday::Connection.new(ssl:{ca_file: MySecrets::CERTFILE})
        con.params = {oauth_token: token}
        con.headers = {user_agent: 'pritory'}
        con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
        r1 = con.get "http://api.skroutz.gr/api/skus/#{id}/products"
        return JSON.parse(r1.body)
      rescue ArgumentError => e
        @log.error("Error (query_skroutz3): #{e}")
      rescue OAuth2::Error => e
        @log.error("Response headers: #{e.response.headers}")
        @log.error("Error (query_skroutz3): #{e}")
      end
      check_limit r1
    end

    # Check Skroutz price, returns price
    def skroutz_check id
      begin
        token =  get_token.token
        con = Faraday::Connection.new(ssl:{ca_file: MySecrets::CERTFILE})
        con.params = {oauth_token: token}
        con.headers = {user_agent: 'pritory'}
        con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
        r1 = con.get "http://api.skroutz.gr/api/skus/#{id}/products"
        result = JSON.parse(r1.body)
        return result['products'][0]['price'].to_s
      rescue JSON::ParserError => e
        @log.error("Parse error (skroutz_check): #{e}")
      rescue ArgumentError => e
        @log.error("Argument Error (skroutz_check): #{e}")
      rescue OAuth2::Error => e
        @log.error("Response headers: #{e.response.headers}")
        @log.error("#{e}")
      end
      check_limit r1
    end
  end
end
