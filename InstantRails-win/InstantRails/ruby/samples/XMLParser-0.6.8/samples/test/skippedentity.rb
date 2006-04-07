#! /usr/local/bin/ruby

require 'xml/parser'

p = XML::Parser.new

def p.skippedEntity(entityName, is_param_ent)
  p(["skippedEntity", entityName, is_param_ent])
end

def p.default(data)
 p(["default", data])
end

def startElement(name, attrs)
  p(["startElement", name, attrs])
end

def endElement(name)
  p(["endElement", name])
end

def p.character(data)
  p(["character", data])
end

def p.externalEntityRef(context, base, sys, pub)
  p(["externalEntityRef", context, base, sys, pub])
  extp = XML::Parser.new(self, context)
  extp.parse(<<EOF)
<!ENTITY % tttt "<!ENTITY test 'BOKE'>">
<!ENTITY test "%tttt;">
<!ENTITY test1 "%Tttt;">
%aaaa;
EOF
  extp.done
end
p.setParamEntityParsing(1)

p.parse(<<EOF)
<!DOCTYPE test SYSTEM "ext.dtd" [
<!--ENTITY test "HOGE"-->
%TTTT;
]>
<test>
  &test;
</test>
EOF
