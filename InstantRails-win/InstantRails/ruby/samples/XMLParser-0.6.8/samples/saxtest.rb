#! /usr/local/bin/ruby

## SAX test
## 1999 yoshidam

require 'xml/saxdriver'

class TestHandler < XML::SAX::HandlerBase
  def getPos
    [@locator.getSystemId, @locator.getLineNumber]
  end

  def getAttrs(attrs)
    ret = []
    for i in 0...attrs.getLength
      ret .push([attrs.getName(i), attrs.getValue(i)])
    end
    ret
  end

  def startDocument
    p ["startDocument", getPos]
  end
  def endDocument
    p ["endDocument", getPos]
  end
  def startElement(name, attr)
    p ["startElement", name, getAttrs(attr), getPos]
  end
  def endElement(name)
    p ["endElement", name, getPos]
  end
  def characters(ch, start, length)
    p ["characters", ch[start, length], getPos]
  end
  def processingInstruction(target, data)
    p ["processingInstruction", target, data, getPos]
  end
  def notationDecl(name, pubid, sysid)
    p ["notationDecl", name, pubid, sysid, getPos]
  end
  def unparsedEntityDecl(name, pubid, sysid, notation)
    p ["unparsedEntityDecl", name, pubid, sysid, notation, getPos]
  end

  def resolveEntity(pubid, sysid)
    p ["resolveEntity", pubid, sysid]
  end

  def setDocumentLocator(loc)
    @locator = loc
  end

  def fatalError(e)
    print "*** FATAL ERROR ***\n"
    raise e
  end
end

p = XML::SAX::Helpers::ParserFactory.makeParser("XML::Parser::SAXDriver")
h = TestHandler.new
p.setDocumentHandler(h)
p.setDTDHandler(h)
p.setEntityResolver(h)
p.setErrorHandler(h)
begin
  p.parse(ARGV[0])
rescue XML::SAX::SAXParseException
  p(["ParseError", $!.getSystemId, $!.getLineNumber, $!.getMessage])
end
