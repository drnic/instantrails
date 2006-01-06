module Fox
  #
  # Status bar
  #
  # === Status bar options
  #
  # +STATUSBAR_WITH_DRAGCORNER+:: Causes the drag corner to be shown
  #
  class FXStatusBar < FXHorizontalFrame
  
    # The status line widget [FXStatusLine]
    attr_reader :statusLine
    
    # The drag corner widget [FXDragCorner]
    attr_reader :dragCorner
    
    # If +true+, the drag corner is shown [Boolean]
    attr_accessor :cornerStyle
  
    #
    # Return an initialized FXStatusBar instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this status bar [FXComposite]
    # +opts+::	status bar options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    # +hs+::	horizontal spacing between widgets, in pixels [Integer]
    # +vs+::	vertical spacing between widgets, in pixels [Integer]
    #
    def initialize(p, opts=0, x=0, y=0, w=0, h=0, pl=3, pr=3, pt=2, pb=2, hs=4, vs=0) # :yields: theStatusBar
    end
  end
end

