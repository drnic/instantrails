#! /usr/local/bin/ruby

require 'xml/parser'

p = XML::Parser.new(nil, " ")
p.setReturnNSTriplet(true);

def p.startDoctypeDecl(name, sysid, pubid, has_internal) end
def p.endDoctypeDecl() end
def p.elementDecl(name, model) end
def p.attlistDecl(name, elname, attname, att_type, dflt, isreq) end
def p.xmlDecl(version, enc, standalone) end
def p.entityDecl(name, param, value, base, sysid, pubid, notation) end
def p.startElement(name, attrs) end
def p.endElement(name) end

p.parse($<.read) do |t, n, d|
  p([t, n, d])
end
