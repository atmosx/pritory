# encoding: utf-8
require 'sequel'
require 'tzinfo'
require_relative "#{File.dirname(__FILE__)}/../mysecrets"

# Database options
DB = Sequel.mysql2 'pritory', user:MySecrets::DBUSER, password: MySecrets::DBPASS, host:'localhost'
tz = TZInfo::Timezone.get('Europe/Athens')

# Create user table
DB.create_table?(:users, engine: 'InnoDB') do 
	primary_key :id
	String :username, null: false, unique: true
	String :password_hash, 	null: false
  String :realname
  String :email, null: false, unique: true
  String :store_name, default: "MyStore"
	DateTime :created_at, default: tz.now
end

# Create product table
DB.create_table?(:products, engine: 'InnoDB') do
	primary_key :id
  Integer :user_id, null: false
  String :category, null: false
  Float  :vat_category, null: false
  String :name, null: false
  String :barcode
  String :description
  String :img_url
  # For details: http://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency
	Numeric :cost, size: [10,2] , null: false 
	String :notes 
	DateTime :created_at, default: tz.now
end

# Create price source
DB.create_table?(:sources, engine: 'InnoDB') do
  primary_key :id
  Integer :product_id, null: false
  String :source, null: false
  Integer :skroutz_id, default: 0
	Numeric :price, size: [10,2] , null: false 
	DateTime :created_at, default: tz.now
end

require_relative 'user'
require_relative 'product'
require_relative 'source'
