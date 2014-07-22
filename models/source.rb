class Source < Sequel::Model
  many_to_one :product
end
