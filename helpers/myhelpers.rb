# encoding: utf-8

module MyHelpers
  # We save cents in the SQL database
  # http://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency
  # Expected value is 'Numeric' in the database, then we convert cents to euro 'string' ready for display
  def self.cents_to_euro value
    raise ArgumentError, 'Price is not numeric!' unless value.is_a? Numeric
    euro = value.to_f/100
    c = sprintf("%0.2f", euro)
    # display value in European format
    c.to_s.sub('.', ',') + " €"
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
    c = sprintf("%0.2f", v)
    # display value in European format
    c.to_s.sub('.', ',') + " %"
  end

  # Collect data (hash) for Multiple Line Chart
  def self.make_graph array
    stores = []
    array.each {|e| stores << e[:name] unless stores.include? e[:name]}
    h = {}
    stores.each do |s|
      h1 = {}
      array.each do |e|
        if e[:name] == s
          h1[e[:created_at]] = (e[:price].to_i/100).to_f
        end
      end
      sorted = h1.sort_by {|a, b| a}
      h[s] = sorted 
    end
    return h
  end

  # Create a string of links
  def linked_array array
    postfix = '</span>'
    html = ''
    array.each do |e|
      prefix = %Q(<span style="";>)
      html += prefix + e + postfix
    end
    return html
  end

  # Convert DB Numeric to float (EUR)
  def self.numeric_to_float value
    raise ArgumentError, 'Value is not numeric!' unless value.is_a? Numeric
    (value.to_f/100).to_f
  end

  # Convert BD Numeric to float without vat
  def self.numeric_no_vat value, vat
    raise ArgumentError, 'Value is not numeric!' unless value.is_a? Numeric
    raise ArgumentError, 'Vat is not float!' unless vat.is_a? Float
    ((value.to_f/100).to_f / (1 + vat/100).to_f).to_f
  end

  # find lowest price of product in the market (except from our store)
  def self.price_diff id, storename
    a = Product.find(id: id)
    # Find my most recent price for product
    sorted = a.sources_dataset.where(name: storename).sort_by {|h| h[:created_at]}
    my_price = sorted.last[:price].to_i
    # Find the most recent price from competitors. Select the lowest price from competitors
    sources = []
    lowest_price = 0
    a.sources_dataset.exclude(name: storename).each {|x| sources << x[:name] unless sources.include? x[:name]}
    sources.each do |s|
      b = a.sources_dataset.where(name: s).last
      price = b[:price].to_i

      case lowest_price
      when 0
        lowest_price = price
      when lowest_price > price
        lowest_price = price
      else
        # do nothing
      end
    end
    # If result is positive, competition price is higher
    # if result is negative our price is lower
    # if 0 competition price and our price are equal
    result = (my_price - lowest_price).to_f/100
    result
  end

end
