#! /usr/local/bin/ruby

## DOMHASH without DOM tree
## 1999 by yoshidam
##
## Namespace support required
##

require 'xml/parser'
require 'md5'
#require 'uconv'

module XML
  class ExtEntParser < Parser
    def initialize(parent, *rest)
      super
      @parent = parent
    end

    def startElement(name, attr)
      @parent.startElement(name, attr)
    end

    def endElement(name)
      @parent.endElement(name)
    end

    def character(data)
      @parent.character(data)
    end

    def processingInstruction(target, data)
      @parent.processingInstruction(target, data)
    end

    def comment(data)
      @parent.comment(data)
    end

    def externalEntityRef(context, base, systemId, publicId)
      extp = ExtEntParser.new(self, context)
      begin
        tree = extp.parse(open(systemId).read)
      rescue XML::ParserError
        raise XML::ParserError.new("#{systemId}(#{extp.line}): #{$!}")
      rescue Errno::ENOENT
        raise Errno::ENOENT.new("#{$!}")
      end
      extp.done
    end
  end

  class DigestParser < Parser
    NODE_NODE = 0
    ELEMENT_NODE = 1
    ATTRIBUTE_NODE = 2
    TEXT_NODE = 3
    CDATA_SECTION_NODE = 4
    ENTITY_REFERENCE_NODE = 5
    ENTITY_NODE = 6
    PROCESSING_INSTRUCTION_NODE = 7
    COMMENT_NODE  = 8
    DOCUMENT_NODE = 9
    DOCUMENT_TYPE_NODE = 10
    DOCUMENT_FRAGMENT_NODE = 11
    NOTATION_NODE = 12

    def initialize(*rest)
      super
      @elem_stack = []
      @elem_data = [ "#document", [], [] ]
      @text = ''
      @root = nil
    end

    ## convert UTF-8 into UTF-16BE
    def tou16(str)
#      Uconv.u16swap(Uconv.u8tou16(str))
      str.unpack("U*").pack("n*")
    end

    ## create digest value for the text node
    def textDigest(text)
      MD5.new([TEXT_NODE].pack("N") + tou16(text)).digest
    end

    ## create digest value for the element  node
    def elementDigest(name, attrs, children)
      MD5.new([ELEMENT_NODE].pack("N") +
              tou16(name) +
              "\0\0" +
              [attrs.length].pack("N") +
              attrs.join +
              [children.length].pack("N") +
              children.join).digest
    end

    ## create digest value for the attribute node
    def attrDigest(name, value)
      MD5.new([ATTRIBUTE_NODE].pack("N") +
              tou16(name) + "\0\0" + tou16(value)).digest
    end

    def processingInstructionDigest(target, data)
      MD5.new([PROCESSING_INSTRUCTION_NODE].pack("N") +
              tou16(target) + "\0\0" + tou16(data)).digest
    end

    ## flush a bufferd text
    def flushText
      if @text.length > 0
        @elem_data[2].push(textDigest(@text))
        @text = ''
      end
    end

    ## start element handler
    def startElement(name, attr)
      flushText
      @elem_stack.push(@elem_data)
      attr_digests = []
      attr_array = attr.sort {|a, b|
        tou16(a[0]) <=> tou16(b[0])
      }
      attr_array.each {|a|
        attr_digests.push(attrDigest(a[0], a[1]))
      }
      @elem_data = [name, attr_digests, []]
    end

    ## end element handler
    def endElement(name)
      flushText
      digest = elementDigest(*@elem_data)
      @elem_data = @elem_stack.pop
      @elem_data[2].push(digest)

      ## digest for root element
      if @elem_stack.length == 0
        @root = digest
      end
    end

    ## character data handler
    def character(data)
      ## Character data must be concatenated because expat split a text
      ## node into some fragments.
      @text << data
    end

    ## PI handler
    def processingInstruction(target, data)
      flushText
      @elem_data[2].push(processingInstructionDigest(target, data))
    end

    ## comment handler
    def comment(data)
      flushText
      ## ignore comment node
    end

    def externalEntityRef(context, base, systemId, publicId)
      extp = ExtEntParser.new(self, context)
      begin
        tree = extp.parse(open(systemId).read)
      rescue XML::ParserError
        raise XML::ParserError.new("#{systemId}(#{extp.line}): #{$!}")
      rescue Errno::ENOENT
        raise Errno::ENOENT.new("#{$!}")
      end
      extp.done
    end

    def getRootDigest
      @root
    end
  end
end

p = XML::DigestParser.new(nil, ":") ## nssep must be ':'
if p.respond_to?(:setParamEntityParsing)
  p.setParamEntityParsing(XML::Parser::PARAM_ENTITY_PARSING_UNLESS_STANDALONE)
end
begin
  p.parse($<.read)
rescue XML::ParserError
  print "#{$<.filename}:#{p.line}: #{$!}\n"
  exit
end
p.getRootDigest.each_byte { |c|; print "%02X" % c }
print "\n"
