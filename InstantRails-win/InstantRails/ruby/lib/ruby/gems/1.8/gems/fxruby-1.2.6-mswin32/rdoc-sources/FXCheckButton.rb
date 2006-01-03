module Fox
  # A check button is a tri-state button.  Normally, it is either
  # +TRUE+ or +FALSE+, and toggles between +TRUE+ or +FALSE+ whenever it is pressed.
  # A third state +MAYBE+ may be set to indicate that no selection has been made yet
  # by the user, or that the state is ambiguous.
  #
  # === Events
  #
  # The following messages are sent by FXCheckButton to its target:
  #
  # +SEL_KEYPRESS+::		sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::		sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::		sent when the button is clicked.
  #
  # === CheckButton styles
  #
  # +CHECKBUTTON_AUTOGRAY+::  Automatically gray out when not updated
  # +CHECKBUTTON_AUTOHIDE+::  Automatically hide when not updated
  # +CHECKBUTTON_PLUS+::      Draw a plus sign for unchecked and minus sign for checked
  # +CHECKBUTTON_NORMAL+::    <tt>JUSTIFY_NORMAL|ICON_BEFORE_TEXT</tt>
  
  class FXCheckButton < FXLabel

    # Check button state (+TRUE+, +FALSE+ or +MAYBE+) [Integer]
    attr_accessor :checkState
    
    # Check button style [Integer]
    attr_accessor :checkButtonStyle
    
    # Box background color [FXColor]
    attr_accessor :boxColor
    
    # Box check color [FXColor]
    attr_accessor :checkColor

    # Construct new check button
    def initialize(parent, text, target=nil, selector=0, opts=CHECKBUTTON_NORMAL, x=0, y=0, width=0, height=0, padLeft=DEFAULT_PAD, padRight=DEFAULT_PAD, padTop=DEFAULT_PAD, padBottom=DEFAULT_PAD) # :yields: theCheckButton
    end
  end
end