module Fox
  #
  # Dial
  #
  # === Events
  #
  # The following messages are sent by FXDial to its target:
  #
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_CHANGED+::             sent when the dial's value changes; the message data is the new value.
  # +SEL_COMMAND+::
  #   sent when the user stops changing the dial's value and releases the mouse button; the message data is the new value.
  #
  # === Dial style options
  #
  # +DIAL_VERTICAL+::     Vertically oriented
  # +DIAL_HORIZONTAL+::   Horizontal oriented
  # +DIAL_CYCLIC+::       Value wraps around
  # +DIAL_HAS_NOTCH+::    Dial has a Center Notch
  # +DIAL_NORMAL+::       same a +DIAL_VERTICAL+
  #
  class FXDial < FXFrame

    # Dial value [Integer]
    attr_accessor :value
    
    # Dial range [Range]
    attr_accessor :range

    #
    # The revolution increment is the amount of change in the position
    # for revolution of the dial; the dial may go through multiple revolutions
    # to go through its whole range. [Integer]
    #
    attr_accessor :revolutionIncrement

    #
    # The spacing for the small notches; this should be set 
    # in tenths of degrees in the range [1,3600], and the value should
    # be a divisor of 3600, so as to make the notches come out evenly. [Integer]
    #
    attr_accessor :notchSpacing

    #
    # The notch offset is the position of the center notch; the value should
    # be tenths of degrees in the range [-3600,3600]. [Integer]
    #
    attr_accessor :notchOffset
    
    # Current dial style [Integer]
    attr_accessor :dialStyle
    
    # Center notch color [FXColor]
    attr_accessor :notchColor
    
    # Status line help text for this dial [String]
    attr_accessor :helpText
    
    # Tool tip message for this dial
    attr_accessor :tipText

    # Construct a dial widget
    def initialize(p, tgt=nil, sel=0, opts=DIAL_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theDial
    end
  end
end

