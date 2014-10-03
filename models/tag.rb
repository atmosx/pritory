class Tag < Sequel::Model
  many_to_many :products
end

