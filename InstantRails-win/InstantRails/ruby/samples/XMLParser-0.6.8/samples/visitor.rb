#! /usr/local/bin/ruby

## Visitor sample
## 1998 by yoshidam
##
## The sample for Ruby style visitor.
## You can use "each" method as the iterator to visit all nodes,
## and can also use the other Enumerable module methods.

require 'xml/dom/builder'
require 'xml/dom/visitor'
require 'xml/encoding-ja'
include XML::Encoding_ja

p = XML::SimpleTreeBuilder.new(1)
tree = p.parse($<.read)
tree.documentElement.normalize

tree.each_with_index do |node, index|
  print format("%03d: ", index)
  case node.nodeType
  when XML::SimpleTree::Node::ELEMENT_NODE
    print "<#{node.nodeName}>\n"
  when XML::SimpleTree::Node::DOCUMENT_NODE
    print "#DOCUMENT\n"
  else
    print "#{Uconv.u8toeuc(node.to_s).inspect}\n"
  end
end
