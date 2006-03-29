#! /usr/local/bin/ruby

require 'xml/parser'
require 'nkf'
#require 'uconv'

class XMLRetry<Exception; end

class SampleParser<XML::Parser
  def startElement(name, attr)
    line = self.line
    column = self.column
    byteIndex = self.byteIndex
    print "L#{line}, #{column}, #{byteIndex}\n"
    attr.each do |key, value|
#      print Uconv.u8toeuc("A#{key} CDATA #{value}\n")
      print "A#{key} CDATA #{value}\n"
    end
#    print Uconv.u8toeuc("(#{name}\n")
    print "(#{name}\n"
    self.defaultCurrent
  end
  private :startElement

  def endElement(name)
#    print Uconv.u8toeuc(")#{name}\n")
    print ")#{name}\n"
  end 
  private :endElement

  def character(data)
    data.gsub!("\n", "\\n")
#    print Uconv.u8toeuc("-#{data}\n")
    print "-#{data}\n"
  end
  private :character

  def processingInstruction(target, data)
    data.gsub!("\n", "\\n")
#    print Uconv.u8toeuc("?#{target} #{data}\n")
    print "?#{target} #{data}\n"
  end
  private :processingInstruction

  def default(data)
    return if data =~ /^<\?xml /
    data.gsub!("\n", "\\n")
#    print Uconv.u8toeuc("//#{data}\n")
    print "//#{data}\n"
  end
  private :default

end

xml = $<.read

parser = SampleParser.new
def parser.unknownEncoding(e)
  raise XMLRetry, e
end

begin
  parser.parse(xml)
rescue XMLRetry
  newencoding = nil
  e = $!.to_s
  if e =~ /^iso-2022-jp$/i
    xml = NKF.nkf("-Je", xml)
    newencoding = "EUC-JP"
  end
  parser = SampleParser.new(newencoding)
  retry
rescue XML::Parser::Error
  line = parser.line
  print "Parse error(#{line}): #{$!}\n"
end
