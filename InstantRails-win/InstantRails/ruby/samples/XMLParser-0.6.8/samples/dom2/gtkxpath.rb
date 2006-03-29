#! /usr/local/bin/ruby

## XPath demo for Gtk
## 1999 by yoshidam
##

require 'gtk'
require 'xml/dom2/core'
require 'xml/dom2/dombuilder'
require 'xml/dom2/xpath'
#require 'uconv'

GC.disable

## TREE_MODE = 0: expand entity references, and not create DOCUMENT_TYPE_NODE
## TREE_MODE = 1: not expand entity references
TREE_MODE = 0
## enpand tree at the beginning
EXPAND_TREE = false
## trim extra white spaces
TRIM = true
## concatenate folding lines
UNFOLD = false
## parse external entity
PARSE_EXT = true

## Gtk resources
#Gtk::RC::parse_string <<EOS
#style "default" {
#  fontset = "-*-helvetica-medium-r-normal--12-*-*-*-*-*-*-*,\ 
#             -*-fixed-medium-r-normal--14-*-*-*-*-*-jisx0208.1983-0,*"
#}
#widget_class "*" style "default"
#EOS

def unfold(str)
  str.
    gsub(/([¡¡-ô¦])\n\s*([¡¡-ô¦])/, '\1\2').
    gsub(/([a-z])-\n\s+([a-z])/, '\1\2').
    gsub(/\s+/, ' ')
end

module Gtk
  class TreeItem
    attr :xml_node
    alias initialize0 initialize
    def initialize(*arg)
      initialize0(arg[0])
      @xml_node = arg[1]
    end
  end
end

## Extend the Node class to manipulate the Gtk::Tree
module XML
module DOM
class Node
  ##  a node to Gtk::Tree
  def appendNodeToTree(node)
    if @treeitem.nil?
      raise "Cannot append tree"
    end
    if @tree.nil?
      @tree = Gtk::Tree::new()
      @treeitem.set_subtree(@tree)
      if EXPAND_TREE
        @tree.show
        @treeitem.expand
      end
    end
    @tree.append(node)
  end

  ## create Gtk::Tree from XML::Node tree
  def newTreeItem(parent = nil)
    if !@treeitem.nil?
      raise "tree item already exist"
    end

    case self.nodeType
    when TEXT_NODE
      attr = self.parentNode.attributes
      if attr && attr['xml:space'] != 'preserve'
        self.nodeValue = unfold(self.nodeValue) if UNFOLD
      end
#      str = "\"" + Uconv::u8toeuc(self.nodeValue) + "\""
      str = "\"" + self.nodeValue + "\""
    when CDATA_SECTION_NODE
#      str = "<![CDATA[" + Uconv::u8toeuc(self.nodeValue) + "]]>"
      str = "<![CDATA[" + self.nodeValue + "]]>"
    when PROCESSING_INSTRUCTION_NODE
#      str = "?" + Uconv::u8toeuc(self.nodeValue)
      str = "?" + self.nodeValue
    when ELEMENT_NODE
      attr = ''
      @attr.each do |a|  ## self.attributes do |a|
        attr += a.to_s + ", "
      end if @attr
      attr.chop!
      attr.chop!
#      str = Uconv::u8toeuc(nodeName)
      str = nodeName
      if (attr != '');
#        str += "  (" + Uconv::u8toeuc(attr) + ")"
        str += "  (" + attr + ")"
      end
    when COMMENT_NODE
#      str = "<!--" + Uconv::u8toeuc(self.nodeValue) + "-->"
      str = "<!--" + self.nodeValue + "-->"
    when DOCUMENT_TYPE_NODE
#      str = "#doctype: " + Uconv::u8toeuc(self.nodeName)
      str = "#doctype: " + self.nodeName
    when ENTITY_REFERENCE_NODE
#      str = "&" + Uconv::u8toeuc(self.nodeName) + ";"
      str = "&" + self.nodeName + ";"
    else
#      str = Uconv::u8toeuc(self.nodeName)
      str = self.nodeName
    end
    str.gsub!(/\n/, "\\\\n")
    @treeitem = Gtk::TreeItem::new(str, self)
    @selecting = false
    @treeitem.signal_connect("select") do |w|
#      $text.set_text(Uconv::u8toeuc(w.xml_node.makeXPath)) unless @selecting
      $text.set_text(w.xml_node.makeXPath) unless @selecting
    end
    if (parent.nil? && !self.parentNode.nil?)
      self.parentNode.appendNodeToTree(@treeitem)
    else
      parent.append(@treeitem)
    end
    @treeitem.show
    self.childNodes do |c|
      c.newTreeItem
    end
  end

  def selectNode
    @selecting = true
    parentNode.showTree if parentNode
    if @treeitem
      @treeitem.activate
    else
      print "Unseen node on the tree view\n"
    end
    @selecting = false
  end

  def showTree
    if parentNode
      parentNode.showTree
    end
    @tree.show if @tree
  end

  def deselect
    @treeitem.deselect
    childNodes do |node|
      node.deselect
    end
  end
end
end
end

## create XML tree
builder = XML::DOM::DOMBuilder.new
builder.setBase("./")
begin
  xmltree = builder.parse($<.read, PARSE_EXT)
rescue XML::Parser::Error
  line = builder.line
  print "#{$0}: #{$!} (in line #{line})\n"
  exit 1
end
print "Parsing end\n"
GC.start

## unify sequential Text nodes
xmltree.documentElement.normalize
xmltree.trim if TRIM
print "Normalization end\n"
GC.start

## create Gtk window
window = Gtk::Window::new(Gtk::WINDOW_TOPLEVEL)
window.signal_connect("delete_event") { exit }
window.signal_connect("destroy_event") { exit }

window.border_width(10)
window.set_title($<.filename)

box1 = Gtk::VBox::new(FALSE, 5)
box1_h = Gtk::HBox::new(FALSE, 5)
window.add(box1)
box1.show
box1.add(box1_h)
box1_h.show

tree = nil
$text = Gtk::Entry.new()
box1_h.pack_start($text, TRUE, TRUE, 0)
$text.show
button = Gtk::Button::new("Find")
button.signal_connect("clicked") do
  text = $text.get_text
  xmltree.deselect
  context = XPath::DOM::Context.new(xmltree)
  begin
    tree.set_selection_mode(Gtk::SELECTION_MULTIPLE)
#    proc = XPath.compile(Uconv.euctou8(text))
    proc = XPath.compile(text)
    result = proc.call(context)
    result.each do |node|
      node.selectNode
    end
  rescue
    ## XPath Error
    print "\a#{$!}: #{text}\n"
  ensure
    tree.set_selection_mode(Gtk::SELECTION_SINGLE)
  end
  1
end
box1_h.pack_start(button, FALSE, FALSE, 0)
button.show

scroll = Gtk::ScrolledWindow.new
scroll.show
scroll.set_usize(600,400)
box1.add(scroll)


tree = Gtk::Tree::new()
##tree.set_selection_mode(Gtk::SELECTION_MULTIPLE)
scroll.add_with_viewport(tree) ## gtk+-1.2
##scroll.add(tree) ## gtk+-1.0
tree.show

## construct Gtk tree
xmltree.newTreeItem(tree)
print "Tree construction end\n"

box2 = Gtk::VBox::new(FALSE, 10)
box2.border_width(10)
box1.pack_start(box2, FALSE, TRUE, 0)
box2.show

button = Gtk::Button::new("Quit")
button.signal_connect("clicked") do
  exit
end
box2.pack_start(button, TRUE, TRUE, 0)
button.show


window.show
GC.start
Gtk::main()
