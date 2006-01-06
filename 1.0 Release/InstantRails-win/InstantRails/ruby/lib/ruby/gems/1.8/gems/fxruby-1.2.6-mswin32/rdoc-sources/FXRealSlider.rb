module Fox
  #
  # The slider widget is a valuator widget which provides simple linear value range.
  # Two visual appearances are supported:- the sunken look, which is enabled with
  # the +REALSLIDER_INSIDE_BAR+ option and the regular look.  The latter may have optional
  # arrows on the slider thumb.
  #
  # === Events
  #
  # The following messages are sent by FXRealSlider to its target:
  #
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_MIDDLEBUTTONPRESS+::	sent when the middle mouse button goes down; the message data is an FXEvent instance.
  # +SEL_MIDDLEBUTTONRELEASE+::	sent when the middle mouse button goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::
  #   sent at the end of a slider move; the message data is the new position of the slider (a Float).
  # +SEL_CHANGED+::
  #   sent continuously while the slider is being moved; the message data is an integer indicating
  #   the current slider position.
  #
  # === Real slider control styles
  #
  # +REALSLIDER_HORIZONTAL+::	RealSlider shown horizontally
  # +REALSLIDER_VERTICAL+::		RealSlider shown vertically
  # +REALSLIDER_ARROW_UP+::		RealSlider has arrow head pointing up
  # +REALSLIDER_ARROW_DOWN+::	RealSlider has arrow head pointing down
  # +REALSLIDER_ARROW_LEFT+::	RealSlider has arrow head pointing left
  # +REALSLIDER_ARROW_RIGHT+::	RealSlider has arrow head pointing right
  # +REALSLIDER_INSIDE_BAR+::	RealSlider is inside the slot rather than overhanging
  # +REALSLIDER_TICKS_TOP+::	Ticks on the top of horizontal slider
  # +REALSLIDER_TICKS_BOTTOM+::	Ticks on the bottom of horizontal slider
  # +REALSLIDER_TICKS_LEFT+::	Ticks on the left of vertical slider
  # +REALSLIDER_TICKS_RIGHT+::	Ticks on the right of vertical slider
  # +REALSLIDER_NORMAL+::		same as <tt>REALSLIDER_HORIZONTAL</tt>
  #
  # === Message identifiers
  #
  # +ID_AUTOINC+::	x
  # +ID_AUTODEC+::	x
  #
  class FXRealSlider < FXFrame

    # Slider value [Float]
    attr_accessor :value

    # Slider style [Integer]
    attr_accessor :sliderStyle

    # Slider head size, in pixels [Integer]
    attr_accessor :headSize
    
    # Slider slot size, in pixels [Integer]
    attr_accessor :slotSize
    
    # Slider auto-increment (or decrement) value [Float]
    attr_accessor :increment
    
    # Delta between ticks [Float]
    attr_accessor :tickDelta
    
    # Color of the slot that the slider head moves in [FXColor]
    attr_accessor :slotColor
    
    # Status line help text for this slider [String]
    attr_accessor :helpText
    
    # Tool tip text for this slider [String]
    attr_accessor :tipText
    
    #
    # Return an initialized FXRealSlider instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this slider [FXComposite]
    # +tgt+::	the message target, if any, for this slider [FXObject]
    # +sel+::	the message identifier for this slider [Integer]
    # +opts+::	slider options [Integer]
    # +x+::	initial x-position, when the +LAYOUT_FIX_X+ layout hint is in effect [Integer]
    # +y+::	initial y-position, when the +LAYOUT_FIX_Y+ layout hint is in effect [Integer]
    # +w+::	initial width, when the +LAYOUT_FIX_WIDTH+ layout hint is in effect [Integer]
    # +h+::	initial height, when the +LAYOUT_FIX_HEIGHT+ layout hint is in effect [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, tgt=nil, sel=0, opts=REALSLIDER_NORMAL, x=0, y=0, w=0, h=0, pl=0, pr=0, pt=0, pb=0) # :yields: theRealSlider
    end

    # Set slider range (where _lo_ and _hi_ are Float values).
    def setRange(lo, hi); end

    # Return the slider range as an array of Float values [lo, hi].
    def getRange(); end
  end
end

