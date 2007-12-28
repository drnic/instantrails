#! /usr/local/bin/ruby

require 'xmlextparser'


class TestParser < XML::ExtParser
  def externalParsedEntityDecl(entname, base, sysid, pubid)
    p ["externalParsedEntityDecl", entname, base, sysid, pubid]
  end

  def internalParsedEntityDecl(entname, text)
    p ["internalParsedEntityDecl", entname, text]
  end

  def escapeAttrVal(str)
    ret = ""
    str.scan(/./um) do |c|
      code = c.unpack("U")[0]
      if code == 9 || code == 10 || code == 13
        ret << sprintf("&#x%X;", code)
      elsif c == "&"
        ret << "&amp;"
      elsif c == "\""
        ret << "&quot;"
      elsif c == "<"
        ret << "&lt;"
      else
        ret << c
      end
    end
    ret
  end

  def escapeText(str)
    ret = ""
    str.scan(/./um) do |c|
      code = c.unpack("U")[0]
      if code == 13
        ret << sprintf("&#x%X;", code)
      elsif c == "&"
        ret << "&amp;"
      elsif c == "<"
        ret << "&lt;"
      elsif c == ">"
        ret << "&gt;"
      else
        ret << c
      end
    end
    ret
  end

  def startElement(name, attrs)
    print "<" + name
    attrs.each do |n, v|
      print " " + n + "='" + escapeAttrVal(v) + "'"
    end
    print  ">"
  end

  def endElement(name)
    print "</" + name + ">"
  end

  def character(text)
    print escapeText(text)
  end
end

p = TestParser.new

pos = ARGV[0].rindex("/")
if pos
  p.setBase(ARGV[0][0, pos + 1])
else
  p.setBase("")
end
begin
  p.parse($<.read)
rescue XML::Parser::Error
  p([$!, p.line])
end
