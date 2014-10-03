class Ptag < Sequel::Model
  many_to_one :product
  many_to_one :tag
end

