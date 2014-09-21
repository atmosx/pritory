#!/usr/bin/env ruby

# Last update: 21/09/2014
#
# This script will install a current VAT (value added tax) for some countries
#
# EU Countries VAT: http://ec.europa.eu/taxation_customs/resources/documents/taxation/vat/how_vat_works/rates/vat_rates_en.pdf
# US States VAT: http://en.wikipedia.org/wiki/Sales_taxes_in_the_United_States#By_jurisdiction


require 'yaml'
require 'sequel'
require_relative "#{File.expand_path File.dirname(__FILE__)}/../models/init"

a = YAML::load(File.open("#{File.expand_path File.dirname(__FILE__)}/../extra/country_vat.yml"))

a.each do |entry|
  entry[:vat].each do |v|
    # Check if VAT is already in DB else, remove
    Vat.create(country: entry[:country], state: entry[:state], vat: v, code: entry[:code]) if Vat.where(country: entry[:country], state: entry[:state], vat: v, code: entry[:code]).empty?
  end
end
