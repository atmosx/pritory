class Product < Sequel::Model
  many_to_one :user
  one_to_many :sources
  many_to_many :tags
  # plugin :association_dependencies, :source => :delete
end

