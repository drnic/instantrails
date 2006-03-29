module Fox
  #
  # The ruler widget is placed alongside a document to measure position
  # and size of entities within the document, such as margins, paragraph
  # indents, and tickmarks.
  # The ruler widget sends a +SEL_CHANGED+ message when the indentation or margins
  # are interactively changed by the user.
  #
  # === Events
  #
  # The following messages are sent by FXRuler to its target:
  #
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  #
  # === Ruler options
  #
  # +RULER_NORMAL+::		Default appearance (default)
  # +RULER_HORIZONTAL+::	Ruler is horizontal (default)
  # +RULER_VERTICAL+::		Ruler is vertical
  # +RULER_TICKS_OFF+::		Tick marks off (default)
  # +RULER_TICKS_TOP+::		Ticks on the top (if horizontal)
  # +RULER_TICKS_BOTTOM+::	Ticks on the bottom (if horizontal)
  # +RULER_TICKS_LEFT+::	Ticks on the left (if vertical)
  # +RULER_TICKS_RIGHT+::	Ticks on the right (if vertical)
  # +RULER_TICKS_CENTER+::	Tickmarks centered
  # +RULER_NUMBERS+::		Show numbers
  # +RULER_ARROW+::		Draw small arrow for cursor position
  # +RULER_MARKERS+::		Draw markers for indentation settings
  # +RULER_METRIC+::		Metric subdivision (default)
  # +RULER_ENGLISH+::		English subdivision
  #
  # === Message identifiers:
  #
  # +ID_ARROW+::		write me
  #
  class FXRuler < FXFrame
  
    # Current position [Integer]
    attr_accessor :position
    
    # Document size [Integer]
    attr_accessor :documentSize
  
    # Document size [Integer]
    attr_accessor :edgeSpacing
    
    # Lower document margin [Integer]
    attr_accessor :marginLower

    # Upper document margin [Integer]
    attr_accessor :marginUpper
    
    # First line indent [Integer]
    attr_accessor :indentFirst
    
    # Lower indent [Integer]
    attr_accessor :indentLower
    
    # Upper indent [Integer]
    attr_accessor :indentUpper
    
    # Document number placement [Integer]
    attr_accessor :numberTicks

    # Document major ticks [Integer]
    attr_accessor :majorTicks

    # Document minor ticks [Integer]
    attr_accessor :minorTicks

    # Document tiny ticks [Integer]
    attr_accessor :tinyTicks

    # Pixels per tick spacing [Float]
    attr_accessor :pixelsPerTick
    
    # The text font [FXFont]
    attr_accessor :font
    
    # The slider value [Integer]
    attr_accessor :value
    
    # The ruler style [Integer]
    attr_accessor :rulerStyle
    
    # The current text color [FXColor]
    attr_accessor :textColor
    
    # The status line help text for this ruler [String]
    attr_accessor :helpText
    
    # The tool tip message for this ruler [String]
    attr_accessor :tipText
    
    #
    # Return an initialized FXRuler instance.
    #
    def initialize(p, tgt=nil, sel=0, opts=RULER_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theRuler
    end
  end
end
