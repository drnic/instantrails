#! /usr/local/bin/ruby

require 'xml/parser'


XML1=<<EOF
<!--DOCTYPE test SYSTEM "hoge.dtd" [
<!ENTITY a "internal">
]-->
<test>&a;</test>
EOF

XML2=<<EOF
<!ENTITY a "external">
EOF

p = XML::Parser.new
if p.respond_to?(:useForeignDTD)
  p p.useForeignDTD(ARGV[0].to_i)
else
  puts "XML::Parser#useForeignDTD requires expat-1.95.5 or later"
end

p.setParamEntityParsing(1)
def p.startDoctypeDecl(name, sys, pub, internal)
  p(["startDoctypeDecl", name, sys, pub, internal])
end
def p.endDoctypeDecl()
  p(["endDoctypeDecl"])
end
def p.externalEntityRef(context, base, sys, pub)
  p(["externalEntityRef", context, base, sys, pub])
  extp = XML::Parser.new(self, context)
  extp.parse(XML2)
  extp.done
end

def p.character(data)
  p data
end

p.parse(XML1)
