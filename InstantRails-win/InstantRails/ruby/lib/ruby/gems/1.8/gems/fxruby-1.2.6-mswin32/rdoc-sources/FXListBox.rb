module Fox
  #
  # List Box
  #
  # === Events
  #
  # The following messages are sent by FXListBox to its target:
  #
  # +SEL_COMMAND+::
  #   sent when a new list item is clicked; the message data is the index of the selected item.
  # +SEL_CHANGED+::
  #   sent when a new list item is clicked; the message data is the index of the selected item.
  #
  # === List Box styles
  #
  # +LISTBOX_NORMAL+::		Normal style
  #
  # === Message identifiers
  #
  # +ID_LIST+
  # +ID_FIELD+
  #
  class FXListBox < FXPacker

    # Number of items in the list [Integer]
    attr_reader :numItems

    # Number of visible items [Integer]
    attr_accessor :numVisible

    # Current item's index, or -1 if no current item [Integer]
    attr_accessor :currentItem
    
    # Text font [FXFont]
    attr_accessor :font
  
    # Background color [FXColor]
    attr_reader :backColor
  
    # Text color [FXColor]
    attr_accessor :textColor
    
    # Background color for selected items [FXColor]
    attr_accessor :selBackColor
    
    # Text color for selected items [FXColor]
    attr_accessor :selTextColor
  
    # Status line help text [String]
    attr_accessor :helpText
  
    # Tool tip message [String]
    attr_accessor :tipText

    #
    # Returns an initialized FXListBox instance.
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_SUNKEN|FRAME_THICK|LISTBOX_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theListBox
    end

    #
    # Return +true+ if _index_ is the index of the current item.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemCurrent?(index); end

    #
    # Return the text of the item at the given index.
    # Raises IndexError if _index_ is out of bounds.
    #
    def retrieveItem(index); end

    #
    # Replace the item at _index_ with a new item with the specified _text_,
    # _icon_ and _data_.
    # Raises IndexError if _index_ is out of bounds.
    #
    def setItem(index, text, icon=nil, ptr=nil); end
  
    #
    # Insert a new item at index.
    # Raises IndexError if _index_ is out of bounds.
    #
    def insertItem(index, text, icon=nil, ptr=nil); end
  
    # Add an item to the end of the list.
    def appendItem(text, icon=nil, ptr=nil);
  
    # Prepend an item to the list
    def prependItem(text, icon=nil, ptr=nil); end
  
    #
    # Move item from _oldIndex_ to _newIndex_ and return the new
    # index of the item.
    # Raises IndexError if either _oldIndex_ or _newIndex_ is out of bounds.
    #
    def moveItem(newIndex, oldIndex); end

    #
    # Remove this item from the list.
    # Raises IndexError if _index_ is out of bounds.
    #
    def removeItem(index); end
  
    # Remove all items from the list
    def clearItems(); end
  
    #
    # Search items for item by name, starting from _start_ item; the
    # _flags_ argument controls the search direction, and case sensitivity.
    #
    def findItem(text, start=-1, flags=SEARCH_FORWARD|SEARCH_WRAP); end
  
    #
    # Set text for specified item to _text_.
    # Raises IndexError if _index_ is out of bounds.
    #
    def setItemText(index, text); end
  
    #
    # Return text for specified item.
    # Raises IndexError if _index_ is out of bounds.
    #
    def getItemText(index); end
  
    #
    # Set icon for specified item to _icon_.
    # Raises IndexError if _index_ is out of bounds.
    #
    def setItemIcon(index, icon); end
    
    #
    # Return icon for specified item.
    # Raises IndexError if _index_ is out of bounds.
    #
    def getItemIcon(index); end
    
    #
    # Set user data object for specified item to _ptr_.
    # Raises IndexError if _index_ is out of bounds.
    #
    def setItemData(index, ptr); end

    #
    # Return user data object for specified item.
    # Raises IndexError if _index_ is out of bounds.
    #
    def getItemData(index); end
  
    # Return +true+ if the pane is shown.
    def paneShown?; end
  
    # Sort items using current sort function
    def sortItems; end
  
    alias appendItem <<
  end
end
