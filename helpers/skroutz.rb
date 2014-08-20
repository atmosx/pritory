#!/usr/bin/env ruby

require 'oauth2'
require 'net/http'
require 'json'
require 'faraday'
require_relative "#{File.expand_path File.dirname(__FILE__)}/../mysecrets"

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

    # Skroutz search product
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

    # def testing
    #   token =  get_token.token
    #   con = Faraday.new
    #   con.params = {oauth_token: token}
    #   con.headers = {user_agent: 'pritory'}
    #   con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
    #   r = con.get "https://api.skroutz.gr/api/skus/3378157/products "
    #   p JSON.parse(r.body)
    # end

    # def fetch_category_id 
    #   res = query_skroutz 'osteoflex'
    #   p res
    # p res["categories"][0]
    # token =  get_token.token
    # con = Faraday.new
    # con.params = {oauth_token: token}
    # con.headers = {user_agent: 'pritory'}
    # con.headers = {'Accept' => 'application/vnd.skroutz+json; version=3'}
    # resp = con.get "https://api.skroutz.gr/categories/#{cid}"
    # begin
    #   p JSON.parse(resp.body)
    # rescue JSON::ParserError => e
    #   p e
    # end
    # end

    #fetch_category_id
    # testing
  end
end

# x = Skroutz::Query.new
# p x.query_skroutz('osteoflex')
# {"categories"=>[{"id"=>1405, "name"=>"Συμπληρώματα Διατροφής", "children_count"=>0, "image_url"=>"http://d.scdn.gr/images/categories/large/1405.jpg", "parent_id"=>1281, "fashion"=>false, "show_specifications"=>false, "manufacturer_title"=>"Κατασκευαστές", "match_count"=>10}, {"id"=>1479, "name"=>"Φαρμακευτικά", "children_count"=>0, "image_url"=>"http://c.scdn.gr/images/categories/large/1479.jpg", "parent_id"=>1281, "fashion"=>false, "show_specifications"=>false, "manufacturer_title"=>"Κατασκευαστές", "match_count"=>1}], "meta"=>{"alternatives"=>[], "strong_matches"=>{}, "pagination"=>{"total_results"=>2, "total_pages"=>1, "page"=>1, "per"=>25}}}
