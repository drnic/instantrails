module Fox
  #
  # Dialog box window.
  #
  # When a dialog box receives a +SEL_COMMAND+ message with identifier
  # +ID_CANCEL+ or +ID_ACCEPT+, the dialog box breaks out of the modal
  # loop and returns a completion code of either 0 or 1, respectively.
  #
  # To close a dialog box when it's not running modally, simply call
  # FXDialogBox#hide (or send it the +ID_HIDE+ command message).
  #
  # === Message identifiers
  #
  # +ID_CANCEL+::	Close the dialog, cancel the entry
  # +ID_ACCEPT+::	Close the dialog, accept the entry
  #
  class FXDialogBox < FXTopWindow
    #
    # Construct free-floating dialog.
    #
    def initialize(app, title, opts=DECOR_TITLE|DECOR_BORDER, x=0, y=0, w=0, h=0, padLeft=10, padRight=10, padTop=10, padBottom=10, hSpacing=4, vSpacing=4) # :yields: theDialogBox
    end
  
    #
    # Construct dialog which will always float over the _owner_ window.
    #
    def initialize(owner, title, opts=DECOR_TITLE|DECOR_BORDER, x=0, y=0, w=0, h=0, padLeft=10, padRight=10, padTop=10, padBottom=10, hSpacing=4, vSpacing=4) # :yields: theDialogBox
    end

    #
    # Run a modal invocation of the dialog, with specified initial _placement_.
    #
    def execute(placement=PLACEMENT_CURSOR); end
  end
end

