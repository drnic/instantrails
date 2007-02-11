#! /usr/local/bin/ruby

require 'xml/parser'

class ExtDTDParser < XML::Parser
  def startElement(name, attr)
    p ["startElement", name, attr]
  end

  def endElement(name)
    p ["endElement", name]
  end

  def character(data)
    p ["character", data]
  end

  def externalEntityRef(context, base, systemId, publicId)
    p ["externalEntityRef", context, base, systemId, publicId]
    extp = ExtDTDParser.new(self, context)
    extp.parse(open(systemId).read)
    extp.done ## required
  end
end

p = ExtDTDParser.new(nil, '!')
if p.respond_to?(:setParamEntityParsing)
  p.setParamEntityParsing(XML::Parser::PARAM_ENTITY_PARSING_UNLESS_STANDALONE)
end
begin
  p.parse($<.read)
rescue XML::Parser::Error
  print "#{$!} in l.#{p.line}\n"
end
