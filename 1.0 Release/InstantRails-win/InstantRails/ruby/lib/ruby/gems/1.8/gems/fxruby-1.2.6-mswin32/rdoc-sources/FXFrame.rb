module Fox
  #
  # Base frame
  #
  # === Constants
  #
  # +DEFAULT_PAD+::   Default padding
  #
  class FXFrame < FXWindow
  
    # Frame style [Integer]
    attr_accessor :frameStyle
    
    # Border width, in pixels [Integer]
    attr_reader	:borderWidth
    
    # Top interior padding, in pixels [Integer]
    attr_accessor :padTop
    
    # Bottom interior padding, in pixels [Integer]
    attr_accessor :padBottom
    
    # Left interior padding, in pixels [Integer]
    attr_accessor :padLeft
    
    # Right interior padding, in pixels [Integer]
    attr_accessor :padRight
    
    # Highlight color [FXColor]
    attr_accessor :hiliteColor
    
    # Shadow color [FXColor]
    attr_accessor :shadowColor
    
    # Border color [FXColor]
    attr_accessor :borderColor
    
    # Base GUI color [FXColor]
    attr_accessor :baseColor

    #
    # Construct frame window.
    #
    def initialize(parent, opts=FRAME_NORMAL, x=0, y=0, width=0, height=0, padLeft=DEFAULT_PAD, padRight=DEFAULT_PAD, padTop=DEFAULT_PAD, padBottom=DEFAULT_PAD) # :yields: theFrame
    end
  end
end
