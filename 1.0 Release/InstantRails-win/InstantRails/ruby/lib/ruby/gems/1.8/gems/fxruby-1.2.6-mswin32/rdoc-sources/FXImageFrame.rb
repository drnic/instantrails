module Fox
  #
  # An FXImageFrame is a simple frame widget that displays an FXImage image.
  #
  class FXImageFrame < FXFrame
  
    # The current image being displayed [FXImage]
    attr_accessor :image
    
    #
    # The current justification mode, some combination of the flags
    # +JUSTIFY_LEFT+, +JUSTIFY_RIGHT+, +JUSTIFY_TOP+ and +JUSTIFY_BOTTOM+ [Integer]
    #
    attr_accessor :justify
    
    #
    # Return an initialized FXImageFrame instance.
    #
    def initialize(p, img, opts=FRAME_SUNKEN|FRAME_THICK, x=0, y=0, w=0, h=0, pl=0, pr=0, pt=0, pb=0) # :yields: theImageFrame
    end
  end
end
