#! /usr/local/bin/ruby

## XML Tree viewer for Gtk
## 1998 by yoshidam
##
## Required: ruby-gtk-0.11 (and gtk+-1.0jp)
##           xmlparser-0.4.17
##           uconv-0.2.1

require 'gtk'
require 'xml/dom/builder-ja'

## Extend the Node class to manipulate the Gtk::Tree
module XML
module DOM
class Node
  ## append a node to Gtk::Tree
  def appendNodeToTree(node)
    if @treeitem.nil?
      raise "Cannot append tree"
    end
    if @tree.nil?
      @tree = Gtk::Tree::new()
      @treeitem.set_subtree(@tree)
      @tree.show
      @treeitem.expand
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
      str = "\"" + self.nodeValue + "\""
    when CDATA_SECTION_NODE
      str = "<![CDATA[" + self.nodeValue + "]]>"
    when PROCESSING_INSTRUCTION_NODE
      str = "?" + self.nodeValue
    when ELEMENT_NODE
      attr = ''
      @attr.each do |a|  ## self.attributes do |a|
        attr += a.to_s + ", "
      end if @attr
      attr.chop!
      attr.chop!
      str = self.nodeName
      if (attr != '');
        str += "  (" + attr + ")"
      end
    when COMMENT_NODE
      str = "<!--" + self.nodeValue + "-->"
    when DOCUMENT_TYPE_NODE
      str = "#doctype: " + self.nodeName
    else
      str = self.nodeName
    end
    str.gsub!(/\n/, "\\\\n")
    @treeitem = Gtk::TreeItem::new(str)
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
end
end
end

## Gtk resources
#Gtk::RC::parse_string <<EOS
#style "default"
#{
#  fontset = "-adobe-helvetica-medium-r-normal--*-140-*-*-*-*-*-*,\ 
#             -*-fixed-medium-r-normal--14-*-*-*-*-*-jisx0208.1983-0,*"
#}
#widget_class "*" style "default"
#EOS

## create XML tree
builder = XML::DOM::JapaneseBuilder.new(1)
begin
  xmltree = builder.parseStream($<)
rescue XML::Parser::Error
  line = builder.line
  print "#{$0}: #{$!} (in line #{line})\n"
  exit 1
end
print "Parsing end\n"

## unify sequential Text nodes
xmltree.documentElement.normalize
xmltree.trim
print "Normalization end\n"

## create Gtk window
window = Gtk::Window::new(Gtk::WINDOW_TOPLEVEL)
window.signal_connect("delete_event") { exit }
window.signal_connect("destroy_event") { exit }

window.border_width(10)
window.set_title($<.filename)

box1 = Gtk::VBox::new(FALSE, 5)
window.add(box1)
box1.show

scroll = Gtk::ScrolledWindow.new
scroll.show
scroll.set_usize(300,300)
box1.add(scroll)


tree = Gtk::Tree::new()
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
#  window.destroy
  exit
end
box2.pack_start(button, TRUE, TRUE, 0)
button.show


window.show
Gtk::main()
