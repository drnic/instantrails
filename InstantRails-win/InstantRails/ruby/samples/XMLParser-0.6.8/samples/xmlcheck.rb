#! /usr/local/bin/ruby

## XML checker
## 1999 by yoshidam
##
## Sep 14, 1999 yoshidam: unknownEncoding イベント対応
## Jul 26, 1998 yoshidam: Shift_JIS, ISO-2022-JP 対応
##                        エラー表示形式を SP 形式に変更

require 'xml/parser'
require 'nkf'

class XMLRetry<Exception; end

xml = $<.read

parser = XML::Parser.new
def parser.unknownEncoding(e)
  raise XMLRetry, e
end

begin
  parser.parse(xml)
  print "well-formed\n"
  exit 0
rescue XMLRetry
  newencoding = nil
  e = $!.to_s
  if e =~ /^iso-2022-jp$/i
    xml = NKF.nkf("-Je", xml)
    newencoding = "EUC-JP"
  end
  parser = XML::Parser.new(newencoding)
  retry
rescue XML::Parser::Error
  line = parser.line
  column = parser.column
  print "#{$0}:#{$<.filename}:#{line}:#{column}:E: #{$!}\n"
  exit 1
end
