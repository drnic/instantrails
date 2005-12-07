#! /usr/local/bin/ruby

## DOMHASH test
## 1999 by yoshidam
##
## Namespace support required
##
## Apr 20, 1999 Change for draft-hiroshi-dom-hash-01.txt
##

require 'xml/dom/builder'
require 'xml/dom/digest'

p = XML::DOM::Builder.new(0, nil, ":") ## nssep must be ':'
if p.respond_to?(:setParamEntityParsing)
  p.setParamEntityParsing(XML::Parser::PARAM_ENTITY_PARSING_UNLESS_STANDALONE)
end
begin
  tree = p.parse($<.read, true)
rescue XML::ParserError
  print "#{$<.filename}:#{p.line}: #{$!}\n"
  exit
end
tree.documentElement.normalize
tree.documentElement.getDigest.each_byte { |c|; print "%02X" % c }
print "\n"
