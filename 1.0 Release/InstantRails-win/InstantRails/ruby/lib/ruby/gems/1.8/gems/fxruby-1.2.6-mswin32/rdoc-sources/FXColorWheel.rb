module Fox
  # A color wheel is a widget which controls a color by means
  # of the hue, saturation, value color specification system.
  #
  # === Events
  #
  # The following messages are sent by FXColorWheel to its target:
  #
  # +SEL_CHANGED+::		sent continuously, while the color is changing
  # +SEL_COMMAND+::		sent when the new color is set
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.

  class FXColorWheel < FXFrame

    # Hue [Float]
    attr_accessor :hue
    
    # Saturation [Float]
    attr_accessor :sat
    
    # Value [Float]
    attr_accessor :val
  
    # Status line help text [String]  
    attr_accessor :helpText
  
    # Tool tip message [String]  
    attr_accessor :tipText

    # Construct color wheel
    def initialize(parent, target=nil, selector=0, opts=FRAME_NORMAL, x=0, y=0, width=0, height=0, padLeft=DEFAULT_PAD, padRight=DEFAULT_PAD, padTop=DEFAULT_PAD, padBottom=DEFAULT_PAD) # :yields: theColorWheel
    end
  end
end
