#! /usr/local/bin/ruby

## Visitor test
## 1998 by yoshidam
##

require 'xml/dom/builder'
require 'xml/dom/visitor'

class Writer
  def visit_Document(document)
    document.children_accept(self)
  end

  def visit_Element(element)
    attrs = ""
    element.attributes.each do |attr|
      attrs += " " + attr.to_s
    end
    print "<#{element.nodeName}#{attrs}>"
    element.children_accept(self);
    print "</#{element.nodeName}>"
  end

  def visit_ProcessingInstruction(pi)
    print "<?" + pi.nodeValue + "?>"
  end

  def visit_Text(text)
    print text.nodeValue
  end

  def visit_Comment(comment)
    print "<!--" + comment.nodeValue + "-->"
  end

  def visit_CDATASection(cdata)
    print "<![CDATA[" + cdata.nodeValue + "]]>"
  end
end

doc = XML::DOM::Builder.new.parse($<.read)
doc.accept(Writer.new)
