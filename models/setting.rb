require 'sequel'

class Setting < Sequel::Model
  one_to_one :users
end 
