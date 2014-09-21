class Product < Sequel::Model
  many_to_one :user
  one_to_many :sources
  # plugin :association_dependencies, :source => :delete
end

