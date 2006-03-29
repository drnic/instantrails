module Fox
  #
  # A dock title is used to move its container, a dock bar.
  # The dock title is also used simultaneously to provide a
  # caption above the dock bar.
  #
  class FXDockTitle < FXDockHandler
    # Caption text for the grip [String]
    attr_accessor :caption
    
    # Caption font [FXFont]
    attr_accessor :font
    
    # Caption color [FXColor]
    attr_accessor :captionColor
    
    # Current justification mode [Integer]
    attr_accessor :justify

    #
    # Construct dock bar title widget
    #
    def initialize(p, text, tgt=nil, sel=0, opts=FRAME_NORMAL|JUSTIFY_CENTER_X|JUSTIFY_CENTER_Y, x=0, y=0, w=0, h=0, pl=0, pr=0, pt=0, pb=0)
    end
  end
end
