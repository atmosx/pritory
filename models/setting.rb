class Setting < Sequel::Model
  one_to_one :user
end 
