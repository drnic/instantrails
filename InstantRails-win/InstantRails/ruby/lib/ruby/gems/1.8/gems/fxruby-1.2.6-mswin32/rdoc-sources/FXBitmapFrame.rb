module Fox
  #
  # An FXBitmapFrame is a simple frame widget that displays an FXBitmap image.
  #
  class FXBitmapFrame < FXFrame
  
    # The current image being displayed [FXBitmap]
    attr_accessor :bitmap
    
    # The color used for the "on" bits in the bitmap [FXColor]
    attr_accessor :onColor
    
    # The color used for the "off" bits in the bitmap [FXColor]
    attr_accessor :offColor
    
    #
    # The current justification mode, some combination of the flags
    # +JUSTIFY_LEFT+, +JUSTIFY_RIGHT+, +JUSTIFY_TOP+ and +JUSTIFY_BOTTOM+
    # [Integer]
    #
    attr_accessor :justify
    
    #
    # Return an initialized FXBitmapFrame instance.
    #
    def initialize(p, bmp, opts=FRAME_SUNKEN|FRAME_THICK, x=0, y=0, w=0, h=0, pl=0, pr=0, pt=0, pb=0) # :yields: theBitmapFrame
    end
  end
end
