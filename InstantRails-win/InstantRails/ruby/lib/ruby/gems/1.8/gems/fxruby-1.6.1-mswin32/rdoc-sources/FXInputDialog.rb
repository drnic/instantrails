module Fox
  #
  # An FXInputDialog is a simple dialog which is used
  # to obtain a text string, integer, or real number from the user.
  # A "password" mode allows the key-in to remain hidden.
  #
  # === Input dialog options
  #
  # +INPUTDIALOG_STRING+::	Ask for a string
  # +INPUTDIALOG_INTEGER+::	Ask for an integer number
  # +INPUTDIALOG_REAL+::	Ask for a real number
  # +INPUTDIALOG_PASSWORD+::	Do not reveal key-in
  #
  class FXInputDialog < FXDialogBox

    # Input string [String]
    attr_accessor :text

    # Number of visible columns of text [Integer]
    attr_accessor :numColumns

    #
    # Construct input dialog box with given caption, icon, and prompt text.
    #
    def initialize(owner, caption, label, ic=nil, opts=INPUTDIALOG_STRING, x=0, y=0, w=0, h=0) # :yields: theInputDialog
    end
  
    #
    # Construct free-floating input dialog box with given caption, icon, and prompt text.
    #
    def initialize(anApp, caption, label, ic=nil, opts=INPUTDIALOG_STRING, x=0, y=0, w=0, h=0) # :yields: theInputDialog
    end

    #
    # Change limits (where _lo_ and _hi_ are numbers).
    #
    def setLimits(lo, hi); end
  
    #
    # Return limits (a two-element array of floats).
    #
    def getLimits(); end

    #
    # Prompt the user for a string, with the text field initialized
    # to the specified _initial_ value. Return the input value if the
    # user clicks *OK*, else return +nil+.
    #
    def FXInputDialog.getString(initial, owner, caption, label, ic=nil); end
  
    #
    # Prompt for a string, in a free-floating window..
    #
    def FXInputDialog.getString(initial, app, caption, label, ic=nil); end
  
    #
    # Prompt the user for an integer number, starting from the specified _initial_ value.
    # Return the input value if the user clicks *OK*, else return +nil+.
    # The input is constrained between _lo_ and _hi_.
    #
    def FXInputDialog.getInteger(initial, owner, caption, label, ic=nil, lo=-2147483647, hi=2147483647); end
  
    #
    # Prompt for an integer, in a free-floating window..
    #
    def FXInputDialog.getInteger(initial, app, caption, label, ic=nil, lo=-2147483647, hi=2147483647); end

    #
    # Prompt the user for a real number, starting from the specified _initial_ value.
    # Return the input value if the user clicks *OK*, else return +nil+.
    # The input is constrained between _lo_ and _hi_.
    #
    def FXInputDialog.getReal(initial, owner, caption, label, ic=nil, lo=-1.797693134862315e+308, hi=1.797693134862315e+308); end

    #
    # Prompt for a real number, in a free-floating window..
    #
    def FXInputDialog.getReal(initial, owner, caption, label, ic=nil, lo=-1.797693134862315e+308, hi=1.797693134862315e+308); end
  end
end

