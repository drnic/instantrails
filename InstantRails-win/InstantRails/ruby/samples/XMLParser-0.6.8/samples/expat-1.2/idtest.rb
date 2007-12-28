#! /usr/local/bin/ruby

require 'xmlextparser'

#if XML::Parser.expatVersion != "1.2"
#  raise "This program work with expat-1.2"
#end

p = XML::ExtParser.new

def p.startElement(name, attr)
  idattr =  getIdAttribute
  idvalue = idattr ? attr[idattr] : nil;
  printf("%s: ID=(%s:%s)\n", name, idattr, idvalue)
end

begin
  p.parse($<.read)
rescue XML::Parser::Error
  p([$!, p.line])
end
