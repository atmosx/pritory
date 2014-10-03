class Product < Sequel::Model
  many_to_one :user
  one_to_many :sources
  one_to_many :ptags
  # plugin :association_dependencies, :source => :delete
end

