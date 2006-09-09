module Fox
  # Combobox
  #
  # === Events
  #
  # The following messages are sent by FXComboBox to its target:
  #
  # +SEL_CHANGED+::		sent when the text in the text field changes; the message data is a String containing the new text.
  # +SEL_COMMAND+::		sent when a new item is selected from the list, or when a command message is sent from the text field; the message data is a String containing the new text.
  #
  # === ComboBox styles
  #
  # +COMBOBOX_NO_REPLACE+::     Leave the list the same
  # +COMBOBOX_REPLACE+::        Replace current item with typed text
  # +COMBOBOX_INSERT_BEFORE+::  Typed text inserted before current
  # +COMBOBOX_INSERT_AFTER+::   Typed text inserted after current
  # +COMBOBOX_INSERT_FIRST+::   Typed text inserted at begin of list
  # +COMBOBOX_INSERT_LAST+::    Typed text inserted at end of list
  # +COMBOBOX_STATIC+::         Unchangable text box
  # +COMBOBOX_NORMAL+::         Default options for comboboxes
  #
  # === Message identifiers
  #
  # +ID_LIST+::			identifier associated with the embedded FXList instance
  # +ID_TEXT+::			identifier associated with the embedded FXTextField instance
  #
  class FXComboBox < FXPacker

    # Editable state [Boolean]
    attr_writer	:editable
    
    # Text [String]
    attr_accessor :text
    
    # Number of columns [Integer]
    attr_accessor :numColumns
    
    # Number of items in the list [Integer]
    attr_reader	:numItems
    
    # Number of visible items [Integer]
    attr_accessor :numVisible
    
    # Index of current item, or -1 if no current item [Integer]
    attr_accessor :currentItem
    
    # Text font [FXFont]
    attr_accessor :font
    
    # Combo box style [Integer]
    attr_accessor :comboStyle
    
    # Window background color [FXColor]
    attr_accessor :backColor
    
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
    # Return an initialized FXComboBox instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent widget for this combo-box [FXComposite]
    # +nc+::	number of columns [Integer]
    # +tgt+::	message target [FXObject]
    # +sel+::	message identifier [Integer]
    # +opts+::	the options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	left-side padding, in pixels [Integer]
    # +pr+::	right-side padding, in pixels [Integer]
    # +pt+::	top-side padding, in pixels [Integer]
    # +pb+::	bottom-side padding, in pixels [Integer]
    #
    def initialize(p, nc, tgt=nil, sel=0, opts=COMBOBOX_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theComboBox
    end

    # Return +true+ if combobox is editable
    def editable?() ; end

    # Return +true+ if the item at _index_ is the current item.
    # Raises IndexError if _index_ is out of bounds.
    def itemCurrent?(index) ; end

    # Return the text of the item at the given _index_.
    # Raises IndexError if _index_ is out of bounds.
    def retrieveItem(index) ; end

    # Replace the item at _index_ with a new item with the specified _text_ and user _data_.
    # Raises IndexError if _index_ is out of bounds.
    def setItem(index, text, data=nil) ; end

    # Insert a new item at _index_, with the specified _text_ and user _data_.
    # Raises IndexError if _index_ is out of bounds.
    def insertItem(index, text, data=nil) ; end

    # Append a new item to the list with the specified _text_ and user _data_.
    def appendItem(text, data=nil) ; end

    # Prepend an item to the list with the specified _text_ and user _data_
    def prependItem(text, data=nil) ; end
    
    #
    # Move item from _oldIndex_ to _newIndex_ and return the new index of the item.
    # Raises IndexError if either _oldIndex_ or _newIndex_ is out of bounds.
    #
    def moveItem(newIndex, oldIndex); end

    # Remove the item at _index_ from the list.
    # Raises IndexError if _index_ is out of bounds.
    def removeItem(index) ; end

    # Remove all items from the list
    def clearItems() ; end

    # Set text for the item at _index_.
    # Raises IndexError if _index_ is out of bounds.
    def setItemText(index, text) ; end

    # Get text for the item at _index_.
    # Raises IndexError if _index_ is out of bounds.
    def getItemText(index) ; end

    # Set user _data_ for the item at _index_.
    # Raises IndexError if _index_ is out of bounds.
    def setItemData(index, data) ; end

    # Get data pointer for the item at _index_.
    # Raises IndexError if _index_ is out of bounds.
    def getItemData(index) ; end

    # Return +true+ if the pane is shown.
    def paneShown?() ; end

    # Sort items using current sort function
    def sortItems() ; end
  end
end
