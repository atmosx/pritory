#!/usr/bin/env ruby

require 'oauth2'
require 'net/http'
require 'json'
require 'faraday'
require 'sidekiq'
require_relative "#{File.expand_path File.dirname(__FILE__)}/../mysecrets"

module Skroutz
  class Query

    # Implement simple object counter
    # http://stackoverflow.com/questions/12889509/can-a-class-in-ruby-store-the-number-of-instantiated-objects-using-a-class-inst
    @counter = 0

    class << self
      attr_accessor :counter
    end

    def initialize
      self.class.counter += 1
    end

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

    # Search the product (step 3)
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

    # Check Skroutz price, returns price
    def skroutz_check id
      begin
        token =  get_token.token
        con = Faraday.new
        con.params = {oauth_token: token}
        con.headers = {user_agent: 'pritory'}
        con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
        r1 = con.get "http://api.skroutz.gr/api/skus/#{id}/products"
        result = JSON.parse(r1.body)
        result['products'][0]['price'].to_s
      rescue JSON::ParserError => e
        puts e
      rescue ArgumentError => e
        puts e
      rescue OAuth2::Error => e
        puts "\nResponse headers: #{e.response.headers}"
      end
    end
  end
end
