#! /usr/local/bin/ruby

require 'xmlextparser'

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


p = XML::ExtParser.new
def p.externalParsedEntityDecl; end
def p.internalParsedEntityDecl; end

pos = ARGV[0].rindex("/")
if pos
  p.setBase(ARGV[0][0, pos + 1])
else
  p.setBase("")
end
begin
  p.parse($<.read) do |event, name, data|
    case event
    when XML::Parser::EXTERNAL_PARSED_ENTITY_DECL
      p(["externalParsedEntityDecl", name, data])

    when XML::Parser::INTERNAL_PARSED_ENTITY_DECL
      p(["internalParsedEntityDecl", name, data])


    when XML::Parser::START_ELEM
      print "<" + name
      data.each do |n, v|
        print " " + n + "='" + escapeAttrVal(v) + "'"
      end
      print  ">"

    when XML::Parser::END_ELEM
      print "</" + name + ">"

    when XML::Parser::CDATA
      print escapeText(data)

    end
  end
rescue XML::Parser::Error
  p([$!, p.line])
end
