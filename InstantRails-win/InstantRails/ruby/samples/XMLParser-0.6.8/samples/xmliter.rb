#! /usr/local/bin/ruby

require 'xml/parser'
require 'nkf'
#require 'uconv'

class XMLRetry<Exception; end

xml = $<.read
parser = XML::Parser.new
def parser.default; end
def parser.unknownEncoding(e)
  raise XMLRetry, e
end

begin
  parser.parse(xml) do |type, name, data|
    case type
    when XML::Parser::START_ELEM
      data.each do |key, value|
#        print Uconv.u8toeuc("A#{key} CDATA #{value}\n")
        print "A#{key} CDATA #{value}\n"
      end
#      print Uconv.u8toeuc("(#{name}\n")
      print "(#{name}\n"
    when XML::Parser::END_ELEM
#      print Uconv.u8toeuc(")#{name}\n")
      print ")#{name}\n"
    when XML::Parser::CDATA
      data.gsub!("\n", "\\n")
#      print Uconv.u8toeuc("-#{data}\n")
      print "-#{data}\n"
    when XML::Parser::PI
      data.gsub!("\n", "\\n")
#      print Uconv.u8toeuc("?#{name} #{data}\n")
      print "?#{name} #{data}\n"
    else
      next if data =~ /^<\?xml /
      data.gsub!("\n", "\\n")
#      print Uconv.u8toeuc("//#{data}\n")
      print "//#{data}\n"
    end
  end
rescue XMLRetry
  newencoding = nil
  e = $!.to_s
  if e =~ /^iso-2022-jp$/i
    xml = NKF.nkf("-Je", xml)
    newencoding = "EUC-JP"
  end
  parser = XML::Parser.new(newencoding)
  def parser.default; end
  retry
rescue XML::Parser::Error
  line = parser.line
  print "Parse error(#{line}): #{$!}\n"
end
