# encoding: utf-8

module MyHelpers
  # We save cents in the SQL database
  # http://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency
  # Expected value is 'Numeric' in the database, then we convert cents to euro 'string' ready for display
  def self.cents_to_euro value
    raise ArgumentError, 'Price is not numeric!' unless value.is_a? Numeric
    euro = value.to_f/100
    p = sprintf("%0.2f", euro)
    # display value in European format
    p.to_s.sub('.', ',') + " €"
  end

  # Convert EUR (String) to cents (Numeric) in order to save the data into MySQL as Numeric
  def self.euro_to_cents value
    raise ArgumentError, 'Price is not string' unless value.is_a? String
    (value.to_f * 100).to_i
  end

  # Fetch data from the DB and display percentage
  def self.numeric_to_percentage value
    raise ArgumentError, 'Value is not numeric' unless value.is_a? Numeric
    v = value.to_f*100
    p = sprintf("%0.2f", v)
    # display value in European format
    p.to_s.sub('.', ',') + " %"
  end
end
