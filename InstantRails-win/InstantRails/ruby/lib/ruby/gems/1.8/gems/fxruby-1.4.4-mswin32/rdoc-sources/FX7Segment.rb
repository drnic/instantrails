module Fox
  #
  # Seven-segment (eg LCD/watch style) widget, useful for making
  # indicators and timers.  Besides numbers, the seven-segment
  # display widget can also display some letters and punctuations.
  #
  # === 7 Segment styles
  #
  # +SEVENSEGMENT_NORMAL+::	Draw segments normally
  # +SEVENSEGMENT_SHADOW+::	Draw shadow under the segments
  #
  class FX7Segment < FXFrame
    # The text for this label [String]
    attr_accessor :text
    
    # The text color [FXColor]
    attr_accessor :textColor
    
    # Cell width, in pixels [Integer]
    attr_accessor :cellWidth
    
    # Cell height, in pixels [Integer]
    attr_accessor :cellHeight
    
    # Segment thickness, in pixels [Integer]
    attr_accessor :thickness
    
    # Current text-justification mode [Integer]
    attr_accessor :justify
    
    # Create a seven segment display
    def initialize(p, text, opts=SEVENSEGMENT_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: the7Segment
    end
  
    #
    # Change 7 segment style, where _style_ is either +SEVENSEGMENT_NORMAL+ or
    # +SEVENSEGMENT_SHADOW+.
    #
    def set7SegmentStyle(style); end

    #
    # Return the current 7 segment style, which is either +SEVENSEGMENT_NORMAL+
    # or +SEVENSEGMENT_SHADOW+.
    #
    def get7SegmentStyle(); end
  end
end

