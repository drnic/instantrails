#! /usr/local/bin/ruby

require 'xml/dom2/dombuilder'

b = XML::DOM::DOMBuilder.new
doc = b.parse($<.read)
print doc.to_s, "\n"
