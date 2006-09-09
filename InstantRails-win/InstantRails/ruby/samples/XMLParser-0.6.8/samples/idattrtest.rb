#! /usr/local/bin/ruby

## ID attribute for XPointer test implementation
## 1998 by yoshidam

require 'xml/dom/builder'

## create test XML tree
doc = XML::DOM::Builder.new.parse("
<test>
  <section name=\"section1\">
  <p id='para1'>test</p>
  <p id='para2'>test</p>
  </section>
  <section name=\"section2\">
  </section>
</test>
")

## setup ID attribute
doc._setIDAttr('id')              ## for all element
doc._setIDAttr('name', 'section') ## for section element

## find ID attribute
p doc.getNodesByXPointer("id(section1)")[0].makeXPointer(false)
p doc.getNodesByXPointer("id(section1)")[0].makeXPointer(true)
p doc.getNodesByXPointer("id(para1)")[0].makeXPointer(false)
p doc.getNodesByXPointer("id(para1)")[0].makeXPointer(true)
