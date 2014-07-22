# Load all *.rb files in the current directory
path = File.dirname(__FILE__)
Dir["#{path}/*.rb"].each {|f| require f }
