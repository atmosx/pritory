# encoding: utf-8

module MyHelpers
  # We save cents in the SQL database
  # http://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency
  # convert cents to euro
  def self.cents_to_euro value
     raise ArgumentError, 'Price is not numeric' unless value.is_a? Numeric
     euro = value.to_f/100
     p = sprintf("%0.2f", euro)
    # display value in European format
     p.to_s.sub('.', ',') + " €"
  end

  # convert euro to cents
  def self.euro_to_cents value
     raise ArgumentError, 'Price is not numeric' unless value.is_a? Numeric
     (value * 100).to_i
  end
end

# p MyHelpers.euro_to_cents "12.12".to_f
