#! /usr/local/bin/ruby -Ku

require 'xml/dom/builder'
require 'nkf'
#require 'uconv'

class XMLRetry<Exception; end

#def Uconv.unknown_unicode_handler(u)
#  return '??'
##  return "#[#{format('%04x', u)}]"
#end

class EUCTreeBuilder < XML::DOM::Builder
#  def nameConverter(str)
#    Uconv.u8toeuc(str)
#  end
#  def cdataConverter(str)
#    Uconv.u8toeuc(str)
#  end
end

builder = EUCTreeBuilder.new(1)
def builder.unknownEncoding(e)
  raise XMLRetry, e
end

xml = $<.read

begin
  tree = builder.parse(xml)
rescue XMLRetry
  newencoding = nil
  e = $!.to_s
  if e =~ /^iso-2022-jp$/i
    xml = NKF.nkf("-Je", xml)
    newencoding = "EUC-JP"
  end
  builder = EUCTreeBuilder.new(1, newencoding)
  retry
rescue XML::Parser::Error
  line = builder.line
  print "#{$0}: #{$!} (in line #{line})\n"
  exit 1
end
#print tree.to_s.gsub(/\#\[([0-9a-f]{4})\]/, "&#x\\1;"), "\n"
tree.documentElement.normalize
tree.dump
#print tree

