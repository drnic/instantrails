module Fox
  #
  # An FXFoldingItem is an item in an FXFoldingList widget.
  #
  class FXFoldingItem < FXObject
  
    # Parent item [FXFoldingItem]
    attr_reader		:parent

    # Next sibling item [FXFoldingItem]
    attr_reader		:next

    # Previous sibling item [FXFoldingItem]
    attr_reader		:prev

    # First child item [FXFoldingItem]
    attr_reader		:first

    # Last child item [FXFoldingItem]
    attr_reader		:last

    # Item logically below this item [FXFoldingItem]
    attr_reader		:below

    # Item logically above this item [FXFoldingItem]
    attr_reader		:above

    # Number of child items [Integer]
    attr_reader		:numChildren

    # Item text [String]
    attr_accessor	:text

    # Open icon [FXIcon]
    attr_accessor	:openIcon

    # Closed icon [FXIcon]
    attr_accessor	:closedIcon

    # User data [Object]
    attr_accessor	:data

    # Indicates whether the item is selected [Boolean]
    attr_writer		:selected

    # Indicates whether the item is opened [Boolean]
    attr_writer		:opened

    # Indicates whether the item is expanded [Boolean]
    attr_writer		:expanded

    # Indicates whether the item is enabled [Boolean]
    attr_writer		:enabled

    # Indicates whether the item is draggable [Boolean]
    attr_writer		:draggable

    # Construct a new folding item
    def initialize(text, openIcon=nil, closedIcon=nil, data=nil) # :yields: theItem
    end
    
    # Set the focus on this folding item (_focus_ is either +true+ or +false+)
    def setFocus(focus) ; end

    # Returns +true+ if this item has the focus
    def hasFocus? ; end
    
    # Returns +true+ if this item is selected
    def selected? ; end
    
    # Returns +true+ if this item is opened
    def opened? ; end
    
    # Returns +true+ if this item is expanded
    def expanded? ; end
    
    # Returns +true+ if this item is enabled
    def enabled? ; end
    
    # Returns +true+ if this item is draggable
    def draggable? ; end
    
    # Return +true+ if subitems, real or imagined
    def hasItems?; end
    
    # Change has items flag to +true+ or +false+.
    def hasItems=(flag); end

    # Returns +true+ if this item owns its icons
    def iconOwned? ; end
    
    #
    # Return +true+ if this item is a descendant of _item_.
    #
    def childOf?(item); end

    #
    # Return +true+ if this item is an ancestor of _item_.
    #
    def parentOf?(item); end

    # Returns the item's text
    def to_s
      text
    end
    
    # Get the width of this item
    def getWidth(foldingList) ; end
    
    # Get the height of this item
    def getHeight(foldingList) ; end
    
    # Create this folding item
    def create; end

    # Detach this folding item
    def detach; end

    # Destroy this folding item
    def destroy; end
  end

  # 
  # An FXFoldingList widget resembles an FXTreeList, but it supports a
  # header control to provide each item with multiple columns of text.
  # Subtrees can be collapsed or expanded by double-clicking on an item
  # or by clicking on the optional plus button in front of the item.
  # Each item may have a text and optional open-icon as well as a closed-icon.
  # The items may be connected by optional lines to show the hierarchical
  # relationship.
  # When an item's selected state changes, the folding list emits a +SEL_SELECTED+
  # or +SEL_DESELECTED+ message. If an item is opened or closed, a message
  # of type +SEL_OPENED+ or +SEL_CLOSED+ is sent. When the subtree under an
  # item is expanded, a +SEL_EXPANDED+ or +SEL_COLLAPSED+ message is issued.
  # A change of the current item is signified by the +SEL_CHANGED+ message.
  # In addition, the folding list sends +SEL_COMMAND+ messages when the user
  # clicks on an item, and +SEL_CLICKED+, +SEL_DOUBLECLICKED+, and +SEL_TRIPLECLICKED+
  # when the user clicks once, twice, or thrice, respectively.
  # When items are added or removed, the folding list sends messages of the
  # type +SEL_INSERTED+ or +SEL_DELETED+.
  # In each of these cases, a pointer to the item, if any, is passed in the
  # 3rd argument of the message.
  #
  # === Events
  #
  # The following messages are sent by FXFoldingList to its target:
  #
  # +SEL_KEYPRESS+::		sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::		sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_RIGHTBUTTONPRESS+::	sent when the right mouse button goes down; the message data is an FXEvent instance.
  # +SEL_RIGHTBUTTONRELEASE+::	sent when the right mouse button goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::		sent when a list item is clicked on; the message data is a reference to the item (an FXFoldingItem instance).
  # +SEL_CLICKED+::		sent when the left mouse button is single-clicked in the list; the message data is a reference to the item clicked (an FXFoldingItem instance) or +nil+ if no item was clicked.
  # +SEL_DOUBLECLICKED+::	sent when the left mouse button is double-clicked in the list; the message data is a reference to the item clicked (an FXFoldingItem instance) or +nil+ if no item was clicked.
  # +SEL_TRIPLECLICKED+::	sent when the left mouse button is triple-clicked in the list; the message data is a reference to the item clicked (an FXFoldingItem instance) or +nil+ if no item was clicked.
  # +SEL_OPENED+::		sent when an item is opened; the message data is a reference to the item (an FXFoldingItem instance).
  # +SEL_CLOSED+::		sent when an item is closed; the message data is a reference to the item (an FXFoldingItem instance).
  # +SEL_EXPANDED+::		sent when a sub-tree is expanded; the message data is a reference to the root item for the sub-tree (an FXFoldingItem instance).
  # +SEL_COLLAPSED+::		sent when a sub-tree is collapsed; the message data is a reference to the root item for the sub-tree (an FXFoldingItem instance).
  # +SEL_SELECTED+::		sent when an item is selected; the message data is a reference to the item (an FXFoldingItem instance).
  # +SEL_DESELECTED+::		sent when an item is deselected; the message data is a reference to the item (an FXFoldingItem instance).
  # +SEL_CHANGED+::		sent when the current item changes; the message data is a reference to the current item (an FXFoldingItem instance).
  # +SEL_INSERTED+::		sent after an item is added to the list; the message data is a reference to the item (an FXFoldingItem instance).
  # +SEL_DELETED+::		sent before an item is removed from the list; the message data is a reference to the item (an FXFoldingItem instance).
  #
  # === Folding list styles
  #
  # +FOLDINGLIST_EXTENDEDSELECT+::		Extended selection mode allows for drag-selection of ranges of items
  # +FOLDINGLIST_SINGLESELECT+::		Single selection mode allows up to one item to be selected
  # +FOLDINGLIST_BROWSESELECT+::		Browse selection mode enforces one single item to be selected at all times
  # +FOLDINGLIST_MULTIPLESELECT+::		Multiple selection mode is used for selection of individual items
  # +FOLDINGLIST_AUTOSELECT+::			Automatically select under cursor
  # +FOLDINGLIST_SHOWS_LINES+::			Lines shown
  # +FOLDINGLIST_SHOWS_BOXES+::			Boxes to expand shown
  # +FOLDINGLIST_ROOT_BOXES+::			Display root boxes also
  # +FOLDINGLIST_NORMAL+::			same as +FOLDINGLIST_EXTENDEDLIST+

  class FXFoldingList < FXScrollArea

    # Number of items [Integer]
    attr_reader		:numItems

    # Number of visible items [Integer]
    attr_accessor	:numVisible

    # First root-level item [FXFoldingItem]
    attr_reader		:firstItem

    # Last root-level item [FXFoldingItem]
    attr_reader		:lastItem

    # Current item, if any [FXFoldingItem]
    attr_accessor	:currentItem

    # Anchor item, if any [FXFoldingItem]
    attr_accessor	:anchorItem

    # Item under the cursor, if any [FXFoldingItem]
    attr_reader		:cursorItem

    # Text font [FXFont]
    attr_accessor	:font

    # Parent-child indent amount, in pixels [Integer]
    attr_accessor	:indent

    # Normal text color [FXColor]
    attr_accessor	:textColor

    # Selected text background color [FXColor]
    attr_accessor	:selBackColor

    # Selected text color [FXColor]
    attr_accessor	:selTextColor

    # Line color [FXColor]
    attr_accessor	:lineColor

    # List style [Integer]
    attr_accessor	:listStyle

    # Status line help text for this list [String]
    attr_accessor	:helpText

    #
    # Return an initialized FXFoldingList instance; the folding list is initially empty.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this folding list [FXComposite]
    # +tgt+::	the message target, if any, for this folding list [FXObject]
    # +sel+::	the message identifier for this folding list [Integer]
    # +opts+::	folding list options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    #
    def initialize(p, tgt=nil, sel=0, opts=TREELIST_NORMAL, x=0, y=0, w=0, h=0) # :yields: theFoldingList
    end

    # Prepend a new (possibly subclassed) _item_ as first child of _parentItem_.
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemFirst(parentItem, item, notify=false); end
  
    # Prepend a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_, as first child of _parentItem_.
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemFirst(parentItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end
  
    # Append a new (possibly subclassed) _item_ as last child of _parentItem_.
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemLast(parentItem, item, notify=false); end
  
    # Append a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_, as last child of _parentItem_.
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemLast(parentItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end
  
    # Append a new (possibly subclassed) _item_ after _otherItem_. 
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemAfter(otherItem, item, notify=false); end
  
    # Append a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_ after _otherItem_. 
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemAfter(otherItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end
  
    # Prepend a new (possibly subclassed) _item_ prior to _otherItem_. 
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemBefore(otherItem, item, notify=false); end
  
    # Prepend a new item with given _text_ and optional _openIcon_, _closedIcon_ and user _data_ prior to _otherItem_. 
    # Returns a reference to the newly added item (an FXFoldingItem instance).
    # If _notify_ is +true+, a +SEL_INSERTED+ message is sent to the list's message
    # target after the item is added.
    def addItemBefore(otherItem, text, openIcon=nil, closedIcon=nil, data=nil, notify=false); end

    #
    # Reparent _item_ under _parentItem_.
    #
    def reparentItem(item, parentItem); end
  
    #
    # Move _item_ before _otherItem_ and return a reference to the moved _item_.
    #
    def moveItemBefore(otherItem, item); end
  
    #
    # Move _item_ after _otherItem_ and return a reference to the moved _item_.
    #
    def moveItemAfter(otherItem, item); end

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
  
    # Return item width
    def getItemWidth(item); end
  
    # Return item height
    def getItemHeight(item); end

    # Search items for item by _text_, starting from _startItem_; the
    # _flags_ argument controls the search direction, and case sensitivity.
    # Returns a reference to the matching item, or +nil+ if no match is found.
    def findItem(text, startItem=nil, flags=SEARCH_FORWARD|SEARCH_WRAP); end

    # Scroll the list to make _item_ visible
    def makeItemVisible(item); end
  
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
  
    # Return +true+ if item is selected
    def itemSelected?(item); end
    
    # Return +true+ if item is current
    def itemCurrent?(item); end

    # Return +true+ if item is visible
    def itemVisible?(item); end

    # Return +true+ if item opened
    def itemOpened?(item); end

    # Return +true+ if item expanded
    def itemExpanded?(item); end
  
    # Return +true+ if item is a leaf-item, i.e. has no children
    def itemLeaf?(item); end
  
    # Return +true+ if item is enabled
    def itemEnabled?(item); end

    # Return item hit code: 0 outside, 1 icon, 2 text, 3 box
    def hitItem(item, x, y); end

    # Repaint item
    def updateItem(item); end
  
    # Enable item
    def enableItem(item); end
  
    # Disable item
    def disableItem(item); end
  
    # Select item.
    # If _notify_ is +true+, a +SEL_SELECTED+ message is sent to the list's
    # message target after the item is selected.
    def selectItem(item, notify=false); end

    # Deselect item.
    # If _notify_ is +true+, a +SEL_DESELECTED+ message is sent to the list's
    # message target after the item is deselected.
    def deselectItem(item, notify=false); end
  
    # Toggle item selection.
    # If _notify_ is +true+, a +SEL_SELECTED+ or +SEL_DESELECTED+ message is
    # sent to the list's message target to indicate the change.
    def toggleItem(item, notify=false); end
  
    # Open item.
    # If _notify_ is +true+, a +SEL_OPENED+ message is sent to the list's
    # message target after the item is opened.
    def openItem(item, notify=false); end
  
    # Close item.
    # If _notify_ is +true+, a +SEL_CLOSED+ message is sent to the list's
    # message target after the item is closed.
    def closeItem(item, notify=false); end
  
    # Collapse sub-tree rooted at _tree_.
    # If _notify_ is +true+, a +SEL_COLLAPSED+ message is sent to the list's
    # message target after the sub-tree is collapsed.
    def collapseFolding(tree, notify=false); end

    # Expand sub-tree rooted at _tree_.
    # If _notify_ is +true+, a +SEL_EXPANDED+ message is sent to the list's
    # message target after the sub-tree is expanded.
    def expandFolding(tree, notify=false); end
  
    # Change current item.
    # If _notify_ is +true+, a +SEL_CHANGED+ message is sent to the list's
    # message target after the current item changes.
    def setCurrentItem(item, notify=false); end
  
    # Extend selection from anchor item to _item_.
    # If _notify_ is +true+, a series of +SEL_SELECTED+ and +SEL_DESELECTED+
    # messages may be sent to the list's message target, indicating the changes.
    def extendSelection(item, notify=false); end
    
    # Deselect all items.
    # If _notify_ is +true+, +SEL_DESELECTED+ messages will be sent to the list's
    # message target indicating the affected items.
    def killSelection(notify=false); end
    
    # Sort all items recursively
    def sortItems(); end

    # Sort root items
    def sortRootItems(); end
    
    # Sort children of _item_
    def sortChildItems(item); end
  end
end

