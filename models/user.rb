require 'bcrypt'
require 'sequel'

class User < Sequel::Model
  one_to_many :products
  
  # Password encrypted and salted - using bcrypt 
	def self.login_user_id(username, password)
		return unless username && password
		return unless user_name = first(username: username)
		return unless BCrypt::Password.new(user_name.password_hash) == password
		user_name.id
	end

	# Hash the password before storing to the db
	def password=(new_password)
		self.password_hash = BCrypt::Password.create(new_password)
	end
end
