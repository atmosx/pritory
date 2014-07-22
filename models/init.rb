# encoding: utf-8
require 'sequel'

# Database options
DB = Sequel.mysql2 'pritory', user:'myuser', password:'ok12', host:'localhost'

# Create user table
DB.create_table?(:users, engine: 'InnoDB') do 
	primary_key :id
	String :username, null: false, unique: true
	String :password_hash, 	null: false
  String :realname
end

# Create product table
DB.create_table?(:products, engine: 'InnoDB') do
	primary_key :id
  Integer :user_id, null: false
  String :category
  String :product_name, null: false
  String :product_barcode
  String :product_description
  String :img_url
	DateTime :created_at, default: Time.now
end

# Create source
DB.create_table?(:sources, engine: 'InnoDB') do
  primary_key :id
  Integer :product_id, null: false
  String :source, null: false
	Numeric :price, size: [10,2] , null: false # For details: http://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency 
end

require_relative 'user'
require_relative 'product'
require_relative 'source'
