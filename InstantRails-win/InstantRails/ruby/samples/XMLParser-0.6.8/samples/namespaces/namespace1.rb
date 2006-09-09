#! /usr/local/bin/ruby

require 'xml/parser'

def default; end

p = XML::Parser.new(nil, ":")
#def p.startNamespaceDecl() end
#def p.endNamespaceDecl() end
p.parse($<.read) do |type, name, data|
  case (type)
  when XML::Parser::START_ELEM
    attr = ''
    data.each do |key, value|
      attr += " #{key}=\"#{value}\""
    end
    print "<#{name}#{attr}>"
  when XML::Parser::END_ELEM
    print "</#{name}>"
  when XML::Parser::CDATA
    print data
#  when XML::Parser::START_NAMESPACE_DECL
#    print "start NS: #{name}, #{data}\n"
#  when XML::Parser::END_NAMESPACE_DECL
#    print "start NS: #{name}\n"
  else
    print data
  end
end
