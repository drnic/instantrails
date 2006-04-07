#! /usr/local/bin/ruby

## Visitor test
## 1998 by yoshidam
##
## This sample comes from Ken MacLeod's sample of XML-Grove-0.05
## Copyright (C) 1998 Ken MacLeod

require 'xml/dom/builder'
require 'xml/dom/visitor'

class MyVisitor<XML::DOM::Visitor
  def visit_Element(element, context, *rest)
    context.push(element.nodeName)
    attrs = []
    element.attributes.each do |attr|
      attrs.push(attr.to_s)
    end
    print "#{context.join(' ')} \\\\ (#{attrs.join(' ')})\n"
    super(element, context, *rest)
    print "#{context.join(' ')} //\n"
    context.pop
  end

  def visit_ProcessingInstruction(pi, context, *rest)
    print "#{context.join(' ')} ?? #{pi.target}(#{pi.data})\n"
  end

  def visit_Text(text, context, *rest)
    value = text.nodeValue
    print "#{context.join(' ')} || #{value.dump}\n"
  end
end

doc = XML::DOM::Builder.new.parse($<.read)
doc.accept(MyVisitor.new, [])
