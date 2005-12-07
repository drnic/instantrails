#! /usr/local/bin/ruby

## Visitor test
## 1998 by yoshidam
##
## This sample comes from Ken MacLeod's sample of XML-Grove-0.05
## Copyright (C) 1998 Ken MacLeod

require 'xml/dom/builder'
require 'xml/dom/visitor'

class MyHTML<XML::DOM::Visitor
  def visit_Document(document, *rest)
    document.children_accept_name(self, *rest)
  end

  def visit_Element(element, *rest)
    raise "visit_Element called while using accept_name??\n"
  end

  def visit_EntityReference(eref, *rest)
    print "&#{eref.nodeName};"
  end

  def visit_Text(text, *rest)
    print text.nodeValue
  end

  def visit_name_DATE(element, *rest)
    print Time.new.to_s.gsub!(/ /, "&nbsp;")
  end

  def visit_name_PERL(element, *rest)
    print "I cannot execute Perl scripts!!\n"
  end

  def visit_name_RUBY(element, *rest)
    script = ''
    element.childNodes.each do |node|
      script += node.nodeValue
    end
    begin
      eval(script)
    rescue
      print "Ruby error: #{$!}"
    end
  end


  def method_missing(mid, *rest)
    if mid.id2name =~ /^visit_name_(.+)$/
      name = $1
      element = rest.shift
      print "<#{name}>"
      element.children_accept_name(self, *rest)
      print "</#{name}>"
    else
      raise NameError.new("undefined method `#{mid.id2name}' " +
                          "for #{self.inspect}")
    end
  end
end

doc = XML::DOM::Builder.new.parse($<.read)
doc.accept_name(MyHTML.new, [])
