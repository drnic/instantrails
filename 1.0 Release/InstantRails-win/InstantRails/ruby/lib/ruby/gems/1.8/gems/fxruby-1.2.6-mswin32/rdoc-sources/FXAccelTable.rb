module Fox
  #
  # The accelerator table sends a message to a specific
  # target object when the indicated key and modifier combination
  # is pressed.
  #
  class FXAccelTable < FXObject
    #
    # Construct empty accelerator table.
    #
    def initialize # :yields: acceleratorTable
    end

    #
    # Add an accelerator to the table. The _hotKey_ is a code returned
    # by the Fox.fxparseAccel method. For example, to associate the
    # Ctrl+S keypress with sending a "save" command to a document, you
    # might use code like this:
    #
    #   hotKey = fxparseAccel("Ctrl+S")
    #   accelTable.addAccel(hotKey, doc, FXSEL(SEL_COMMAND, MyDocument::ID_SAVE))
    #
    # ==== Parameters:
    #
    # +hotKey+::	the hotkey associated with this accelerator [Integer]
    # +tgt+::		message target [FXObject]
    # +seldn+::		selector for the +SEL_KEYPRESS+ event [Integer]
    # +selup+::		selector for the +SEL_KEYRELEASE+ event [Integer]
    #
    def addAccel(hotKey, tgt=nil, seldn=0, selup=0) ; end

    #
    # Remove an accelerator from the table.
    #
    def removeAccel(hotKey) ; end

    #
    # Return +true+ if accelerator specified.
    # Here, _hotKey_ is a code representing an accelerator key as returned
    # by the Fox.fxparseAccel method. For example,
    #
    #   if accelTable.hasAccel?(fxparseAccel("Ctrl+S"))
    #     ...
    #   end
    #
    def hasAccel?(hotKey) ; end

    #
    # Return the target object of the given accelerator, or +nil+ if
    # the accelerator is not present in this accelerator table.
    # Here, _hotKey_ is a code representing an accelerator key as returned
    # by the Fox.fxparseAccel method. For example,
    #
    #   doc = accelTable.targetofAccel(fxparseAccel("Ctrl+S"))
    #
    def targetOfAccel(hotKey) ; end
  
    #
    # Remove mapping for specified hot key.
    # Here, _hotKey_ is a code representing an accelerator key as returned
    # by the Fox.fxparseAccel method. For example,
    #
    #   accelTable.removeAccel(fxparseAccel("Ctrl+S"))
    #
    def removeAccel(hotKey) ; end
  end
end
