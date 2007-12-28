#! /usr/local/bin/ruby

require 'xml/dom/builder'
#require 'uconv'

p = XML::DOM::Builder.new
#def p.nameConverter(str)
#  Uconv.u8toeuc(str)
#end
#def p.cdataConverter(str)
#  Uconv.u8toeuc(str)
#end

t = p.parse($<.read)
allelem = t.getElementsByTagName("*")
allelem.each do | node|
  p = node.makeXPointer
  print "#{p}: ["
  t.getNodesByXPointer(p).each do |n|
    print n.makeXPointer(true)
  end
  print "]\n"
end
