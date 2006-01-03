module Fox
  #
  # Real-valued spinner control
  #
  # === Events
  #
  # The following messages are sent by FXRealSpinner to its target:
  #
  # +SEL_KEYPRESS+::	sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::	sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::
  #   sent whenever the spinner's value changes; the message data is an integer
  #   indicating the new spinner value.
  # +SEL_CHANGED+::
  #   sent whenever the text in the spinner's text field changes; the message
  #   data is an integer indicating the new spinner value.
  #
  # === Spinner options
  #
  # +REALSPIN_NORMAL+::	Normal, non-cyclic
  # +REALSPIN_CYCLIC+::	Cyclic spinner
  # +REALSPIN_NOTEXT+::	No text visible
  # +REALSPIN_NOMAX+::	Spin all the way up to infinity
  # +REALSPIN_NOMIN+::	Spin all the way down to -infinity
  # +REALSPIN_LOG+::	Logarithmic rather than linear
  #
  # === Message identifiers
  #
  # +ID_INCREMENT+::	x
  # +ID_DECREMENT+::	x
  # +ID_ENTRY+::	x
  #
  class FXRealSpinner < FXPacker
    # Current value [Float]
    attr_accessor :value

    # Spinner range (low and high values) [Range]
    attr_accessor :range

    # Text font for this spinner [FXFont]
    attr_accessor :font

    # Status line help text for this spinner [String]
    attr_accessor :helpText

    # Tool tip text for this spinner [String]
    attr_accessor :tipText
    
    # Spinner style [Integer]
    attr_accessor :spinnerStyle
    
    # Color of the "up" arrow [FXColor]
    attr_accessor :upArrowColor

    # Color of the "down" arrow [FXColor]
    attr_accessor :downArrowColor

    # Normal text color [FXColor]
    attr_accessor :textColor

    # Background color for selected text [FXColor]
    attr_accessor :selBackColor

    # Foreground color for selected text [FXColor]
    attr_accessor :selTextColor

    # Cursor color [FXColor]
    attr_accessor :cursorColor

    # Number of columns (i.e. width of spinner's text field, in terms of number of columns of 'm') [Integer]
    attr_accessor :numColumns

    #
    # Return an initialized FXRealSpinner instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this spinner [FXComposite]
    # +cols+::	number of columns to display in the text field [Integer]
    # +tgt+::	the message target, if any, for this spinner [FXObject]
    # +sel+::	the message identifier for this spinner [Integer]
    # +opts+::	the options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, cols, tgt=nil, sel=0, opts=REALSPIN_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theRealSpinner
    end
  
    # Increment spinner
    def increment(); end
  
    # Decrement spinner
    def decrement(); end
  
    # Return +true+ if the spinner is in cyclic mode.
    def cyclic?; end
  
    #
    # Set to cyclic mode, i.e. wrap around at maximum/minimum.
    #
    def cyclic=(cyc); end
  
    # Return +true+ if this spinner's text field is visible.
    def textVisible?; end
  
    # Set the visibility of this spinner's text field.
    def textVisible=(shown); end
  
    #
    # Change the spinner increment value, i.e. the amount by which the spinner's
    # value increases when the up arrow is clicked.
    #
    def setIncrement(inc); end

    # Get the spinner increment value.
    def getIncrement(); end

    # Set the "editability" of this spinner's text field.
    def editable=(ed); end
  
    # Return +true+ if the spinner's text field is editable.
    def editable?; end
  end
end

