module Fox
  #
  # Message box
  #
  # === Message box buttons
  #
  # +MBOX_OK+::			Message box has a only an *Ok* button
  # +MBOX_OK_CANCEL+::		Message box has *Ok* and *Cancel* buttons
  # +MBOX_YES_NO+::		Message box has *Yes* and *No* buttons
  # +MBOX_YES_NO_CANCEL+::	Message box has *Yes*, *No*, and *Cancel* buttons
  # +MBOX_QUIT_CANCEL+::	Message box has *Quit* and *Cancel* buttons
  # +MBOX_QUIT_SAVE_CANCEL+::	Message box has *Quit*, *Save*, and *Cancel* buttons
  #
  # === Return values
  #
  # +MBOX_CLICKED_YES+::	The *Yes* button was clicked
  # +MBOX_CLICKED_NO+::		The *No* button was clicked
  # +MBOX_CLICKED_OK+::		The *Ok* button was clicked
  # +MBOX_CLICKED_CANCEL+::	The *Cancel* button was clicked
  # +MBOX_CLICKED_QUIT+::	The *Quit* button was clicked
  # +MBOX_CLICKED_SAVE+::	The *Save* button was clicked
  #
  class FXMessageBox < FXDialogBox
    #
    # Construct message box with given caption, icon, and message text.
    #
    def initialize(owner, caption, text, ic=nil, opts=0, x=0, y=0) # :yields: theMessageBox
    end
  
    #
    # Construct free-floating message box with given caption, icon, and message text.
    #
    def initialize(anApp, caption, text, ic=nil, opts=0, x=0, y=0) # :yields: theMessageBox
    end

    #
    # Show a modal error message; returns one of the return values listed above.
    #
    def FXMessageBox.error(owner, opts, caption, message); end
  
    #
    # Show a modal error message in a free-floating window; returns one of the return values listed above.
    #
    def FXMessageBox.error(app, opts, caption, message); end
  
    #
    # Show a modal warning message; returns one of the return values listed above.
    #
    def FXMessageBox.warning(owner, opts, caption, message); end
  
    #
    # Show a modal warning message in a free-floating window; returns one of the return values listed above.
    #
    def FXMessageBox.warning(app, opts, caption, message); end

    #
    # Show a modal question dialog; returns one of the return values listed above.
    #
    def FXMessageBox.question(owner, opts, caption, message); end
  
    #
    # Show a modal question dialog in a free-floating window; returns one of the return values listed above.
    #
    def FXMessageBox.question(app, opts, caption, message); end

    #
    # Show a modal information dialog; returns one of the return values listed above.
    #
    def FXMessageBox.information(owner, opts, caption, message); end

    #
    # Show a modal information dialog in a free-floating window; returns one of the return values listed above.
    #
    def FXMessageBox.information(app, opts, caption, message); end
  end
end

