module Fox
  # A color well is a widget which controls color settings.
  # Colors may be dragged and dropped from one color well to another.
  # A double-click inside a color well will bring up the standard
  # color dialog panel to edit the color well's color.
  # Colors may be also pasted by name using middle-mouse click into/out of
  # color wells from/to other selection-capable applications; for example,
  # you can highlight the word `red' and paste it into a color well.
  #
  # === Events
  #
  # The following messages are sent from FXColorWell to its target:
  #
  # +SEL_COMMAND+::		sent when a new color is applied
  # +SEL_CHANGED+::		sent when the color changes
  # +SEL_KEYPRESS+::		sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::		sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_MIDDLEBUTTONPRESS+::	sent when the middle mouse button goes down; the message data is an FXEvent instance.
  # +SEL_MIDDLEBUTTONRELEASE+::	sent when the middle mouse button goes up; the message data is an FXEvent instance.
  # +SEL_CLICKED+::		sent when the color well is single-clicked
  # +SEL_DOUBLECLICKED+::	sent when the color well is double-clicked
  # +SEL_TRIPLECLICKED+::	sent when the color well is triple-clicked
  #
  # === Color Well Styles
  #
  # +COLORWELL_OPAQUEONLY+::	Colors must be opaque
  # +COLORWELL_SOURCEONLY+::	This color well is never a target
  # +COLORWELL_NORMAL+::	Same as +JUSTIFY_NORMAL+
  #
  # === Message identifiers
  #
  # +ID_COLORDIALOG+::		x
  
  class FXColorWell < FXFrame

    # The color [FXColor]
    attr_accessor :rgba
    
    # Status line help text [String]
    attr_accessor :helpText
    
    # Tool tip message [String]
    attr_accessor :tipText
    
    # Only opaque colors allowed [Boolean]
    attr_writer :opaqueOnly

    # Construct color well with initial _color_.
    def initialize(parent, color=0, target=nil, selector=0, opts=COLORWELL_NORMAL, x=0, y=0, width=0, height=0, padLeft=DEFAULT_PAD, padRight=DEFAULT_PAD, padTop=DEFAULT_PAD, padBottom=DEFAULT_PAD) # :yields: theColorWell
    end

    # Return +true+ if only opaque colors allowed
    def opaqueOnly?() ; end
  end
end
