#! /usr/local/bin/ruby

require 'xml/parser'

if XML::Parser.respond_to?(:getFeatureList)
  XML::Parser.getFeatureList.each do |key, value|
    puts "#{key}:\t#{value}"
  end
else
  puts "XML::Parser.getFeatureList requires expat-1.95.5 or later"
end
