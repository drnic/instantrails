#! /usr/local/bin/ruby

require 'xml/parserns'

p = XML::ParserNS.new()
def p.startElement(n, a)
  p(["start", resolveElementQName(n)])
  a.each do | n, v|
    p(['attr', resolveAttributeQName(n), v])
  end
end

def p.endElement(n)
  p(["end", resolveElementQName(n)])
end

p.parse($<.read)
# do |t, n, d|
#  p([t, n, d])
#end

