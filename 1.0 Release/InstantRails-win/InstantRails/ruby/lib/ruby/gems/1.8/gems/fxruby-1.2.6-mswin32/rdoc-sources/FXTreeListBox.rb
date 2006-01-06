module Fox
  #
  # Tree list box.
  #
  # === Tree list box styles
  #
  # +TREELISTBOX_NORMAL+::	Normal style
  #
  # === Message identifiers
  #
  # +ID_TREE+::		x
  # +ID_FIELD+::	x
  #
  class FXTreeListBox < FXPacker

    # Number of items [Integer]
    attr_reader :numItems

    # Number of visible items [Integer]
    attr_accessor :numVisible

    # First root-level item [FXTreeItem]
    attr_reader :firstItem

    # Last root-level item [FXTreeItem]
    attr_reader :lastItem

    # Current item, if any [FXTreeItem]
    attr_accessor :currentItem

    # Text font [FXFont]
    attr_accessor :font
    
    # Tree list box style
    attr_accessor :listStyle

    # Status line help text for this tree list box [String]
    attr_accessor :helpText

    # Tool tip text for this tree list box [String]
    attr_accessor :tipText

    #
    # Return an initially empty FXTreeListBox.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this tree list box [FXComposite]
    # +tgt+::	the message target, if any, for this tree list box [FXObject]
    # +sel+::	the message identifier for this tree list box [Integer]
    # +opts+::	tree list options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_SUNKEN|FRAME_THICK|TREELISTBOX_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theTreeListBox
    end

    # Prepend a new (possibly subclassed) _item_ as first child of _parentItem_.
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemFirst(parentItem, item, notify=false); end
  
    # Prepend a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_, as first child of _parentItem_.
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemFirst(parentItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end
  
    # Append a new (possibly subclassed) _item_ as last child of _parentItem_.
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemLast(parentItem, item, notify=false); end
  
    # Append a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_, as last child of _parentItem_.
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemLast(parentItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end
  
    # Append a new (possibly subclassed) _item_ after _otherItem_. 
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemAfter(otherItem, item, notify=false); end
  
    # Append a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_ after _otherItem_. 
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemAfter(otherItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end
  
    # Prepend a new (possibly subclassed) _item_ prior to _otherItem_. 
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemBefore(otherItem, item, notify=false); end
  
    # Prepend a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_ prior to _otherItem_. 
    # Returns a reference to the newly added item (an FXTreeItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemBefore(otherItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end

    # Remove item.
    # If _notify_ is +true+, a +SEL_DELETED+ message is sent to the list's message
    # target before the item is removed.
    def removeItem(item, notify=false);

    # Remove items in range [_fromItem_, _toItem_] inclusively.
    # If _notify_ is +true+, a +SEL_DELETED+ message is sent to the list's message
    # target before each item is removed.
    def removeItems(fromItem, toItem, notify=false); end

    # Remove all items from the list.
    # If _notify_ is +true+, a +SEL_DELETED+ message is sent to the list's message
    # target before each item is removed.
    def clearItems(notify=false); end

    # Search items for item by _text_, starting from _startItem_; the
    # _flags_ argument controls the search direction, and case sensitivity.
    # Returns a reference to the matching item, or +nil+ if no match is found.
    def findItem(text, startItem=nil, flags=SEARCH_FORWARD|SEARCH_WRAP); end

    # Return +true+ if item is current
    def itemCurrent?(item); end

    # Return +true+ if item is a leaf-item, i.e. has no children
    def itemLeaf?(item); end

    # Sort root items
    def sortRootItems(); end

    # Sort all items recursively.
    def sortItems(); end

    # Sort children of _item_
    def sortChildItems(item); end

    #
    # Change current item.
    # If _notify_ is +true+, a SEL_CHANGED message is sent to the tree list box's
    # message target.
    #
    def setCurrentItem(item, notify=false); end
    
    # Change item's text
    def setItemText(item, text); end
    
    # Return item's text
    def getItemText(item); end
  
    # Change item's open icon
    def setItemOpenIcon(item, openIcon); end
    
    # Return item's open icon
    def getItemOpenIcon(item); end
    
    # Change item's closed icon
    def setItemClosedIcon(item, closedIcon); end
    
    # Return item's closed icon
    def getItemClosedIcon(item); end
  
    # Change item's user data
    def setItemData(item, data); end
  
    # Return item's user data
    def getItemData(item); end
  
    # Return +true+ if the pane is shown.
    def paneShown?; end
  end
end

