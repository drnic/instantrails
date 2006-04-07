module Fox
  #
  # The Choice Box provides a dialog panel to select one item out of a list
  # of choices.  The choices are provided as a list of text strings.
  # When the dialog closes, the index of the selected choice is returned,
  # while a -1 is returned if the dialog was canceled,
  #
  class FXChoiceBox < FXDialogBox
    #
    # Construct choice box with given caption, icon, message text, and with choices from array of strings.
    #
    # ==== Parameters:
    #
    # +owner+::		Owner window for this dialog box [FXWindow]
    # +caption+::	Caption for this dialog box [String]
    # +text+::		Message text for this dialog box [String]
    # +icon+::		Icon for this dialog box [FXIcon]
    # +choices+::	Array of strings containing choices [Array]
    # +opts+::		Dialog box options [Integer]
    # +x+::		x-coordinate
    # +y+::		y-coordinate
    # +w+::		width
    # +h+::		height
    #
    def initialize(owner, caption, text, icon, choices, opts=0, x=0, y=0, w=0, h=0) # :yields: theChoiceBox
    end

    #
    # Construct free floating choice box with given caption, icon, message text, and with choices from array of strings.
    #
    # ==== Parameters:
    #
    # +app+::		Reference to the application object [FXApp]
    # +caption+::	Caption for this dialog box [String]
    # +text+::		Message text for this dialog box [String]
    # +icon+::		Icon for this dialog box [FXIcon]
    # +choices+::	Array of strings containing choices [Array]
    # +opts+::		Dialog box options [Integer]
    # +x+::		x-coordinate
    # +y+::		y-coordinate
    # +w+::		width
    # +h+::		height
    #
    def initialize(app, caption, text, icon, choices, opts=0, x=0, y=0, w=0, h=0) # :yields: theChoiceBox
    end

    #
    # Show a modal choice dialog.
    # Prompt the user using a dialog with given caption, icon,
    # message text, and choices from array of strings.
    # Returns -1 if the dialog box is cancelled, otherwise returns the index of the selected choice
    #
    # ==== Parameters:
    #
    # +owner+::		Owner window for this dialog box [FXWindow]
    # +opts+::		Dialog box options [Integer]
    # +caption+::	Caption for this dialog box [String]
    # +text+::		Message text for this dialog box [String]
    # +icon+::		Icon for this dialog box [FXIcon]
    # +choices+::	Array of strings containing choices [Array]
    #
    def FXChoiceBox.ask(owner, opts, caption, text, icon, choices); end

    #
    # Show modal choice message, in free floating window.
    # Prompt the user using a dialog with given caption, icon,
    # message text, and with choices from array of strings.
    # Returns -1 if the dialog box is cancelled, otherwise returns the index of the selected choice
    #
    # ==== Parameters:
    #
    # +app+::		Reference to the application object [FXApp]
    # +opts+::		Dialog box options [Integer]
    # +caption+::	Caption for this dialog box [String]
    # +text+::		Message text for this dialog box [String]
    # +icon+::		Icon for this dialog box [FXIcon]
    # +choices+::	Array of strings containing choices [Array]
    #
    def FXChoiceBox.ask(app, opts, caption, text, icon, choices); end
  end
end

