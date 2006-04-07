#! /usr/local/bin/ruby

require 'xml/dom2/core'

builder = XML::DOM::DOMImplementation.instance.createDOMBuilder
#builder.createCDATASection = true
doc = builder.parseURI(ARGV[0])
doc.each do |a|
   p [a.nodeName, a._getNamespaces(nil)] if a.nodeType == XML::DOM::Node::ELEMENT_NODE
end
