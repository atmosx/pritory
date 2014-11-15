# encoding: utf-8
require 'sequel'
require 'tzinfo'
require_relative "#{File.dirname(__FILE__)}/../mysecrets"

# Database options
if ENV['RACK_ENV'] == 'test'
  DB = Sequel.sqlite
else
  DB = Sequel.mysql2 'pritory', user:MySecrets::DBUSER, password: MySecrets::DBPASS, host:'localhost' 
end

# Create user table
DB.create_table?(:users, engine: 'InnoDB') do 
  primary_key :id
  String :username, null: false, unique: true
  String :password_hash, 	null: false
  DateTime :created_at, default: TZInfo::Timezone.get('Europe/Athens').now
end

# Create product table
DB.create_table?(:products, engine: 'InnoDB') do
  primary_key :id
  Integer :user_id, null: false
  Float  :vat_category, null: false
  String :name, null: false
  String :barcode
  String :img_url
  # For details: http://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency
  Numeric :cost, size: [10,2] , null: false 
  String :notes 
  DateTime :created_at, default: TZInfo::Timezone.get('Europe/Athens').now
end

# Create price source
DB.create_table?(:sources, engine: 'InnoDB') do
  primary_key :id
  Integer :product_id, null: false
  String :name, null: false
  Integer :skroutz_id, default: 0
  Numeric :price, size: [10,2] , null: false 
  # For some reason I can't tell, this returns always the esame exact time!
  DateTime :created_at, default: TZInfo::Timezone.get('Europe/Athens').now
end

# User settings
DB.create_table?(:settings, engine: 'InnoDB') do
  primary_key :id
  Integer :user_id, null: false
  String :email
  String :country
  String :currency
  String :storename
  String :realname
  DateTime :created_at, default: TZInfo::Timezone.get('Europe/Athens').now
end

# VAT system (countries have to be added manually)
DB.create_table?(:vats, engine: 'InnoDB') do
  primary_key :id
  String :country, null: false
  String :state # US has VAT categories on a per state basis
  String :code
  Float :vat, null: false
end

# Tags support
DB.create_table?(:tags, engine: 'InnoDB') do
  primary_key :id
  String :name, null: false
end

# Create join table to add handy methods
DB.create_join_table?(product_id: :products, tag_id: :tags)

# Create join table to add handy methods
DB.create_join_table?(product_id: :products, source_id: :sources)

require_relative 'user'
require_relative 'product'
require_relative 'source'
require_relative 'setting'
require_relative 'vat'
require_relative 'tag'
