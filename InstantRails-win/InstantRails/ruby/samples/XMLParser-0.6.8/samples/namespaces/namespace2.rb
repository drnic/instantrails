#! /usr/local/bin/ruby

require 'xml/parser'

module XML
class Parser
  def initialize(encoding = nil, nssep = nil)
    @nstbl = {nil=>""}
  end

  def startElement(name, attr)
    name =~ /^(([^;]*);)?(.+)$/
    uri = $2
    prefix = @nstbl[uri] || ""
    name = $3
    uri = uri || ""
    print "(" + prefix + "[" + uri + "]:" + name + "\n"
  end

  def endElement(name)
    name =~ /^(([^;]*);)?(.+)$/
    uri = $2
    prefix = @nstbl[uri] || ""
    name = $3
    uri = uri || ""
    print ")" + prefix + "[" + uri + "]:" + name + "\n"
  end

  def startNamespaceDecl(prefix, uri)
    prefix = "" if prefix.nil?
    uri = uri || ""
    @nstbl[uri] = prefix
  end

  def endNamespaceDecl(prefix)
  end
end
end

p = XML::Parser.new(nil, ";")
p.parse($<.read)
