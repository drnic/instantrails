module Fox
  #
  # The tab book layout manager arranges pairs of children;
  # the even numbered children (0,2,4,...) are usually tab items,
  # and are placed on the top.  The odd numbered children are
  # usually layout managers, and are placed below; all the odd
  # numbered children are placed on top of each other, similar
  # to the switcher widget.  When the user presses one of the
  # tab items, the tab item is raised above the neighboring tabs,
  # and the corresponding panel is raised to the top.
  # Thus, a tab book can be used to present many GUI controls
  # in a small space by placing several panels on top of each
  # other and using tab items to select the desired panel.
  #
  class FXTabBook < FXTabBar
    #
    # Return an initialized FXTabBook instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this tar book [FXComposite]
    # +tgt+::	the message target, if any, for this tar book [FXObject]
    # +sel+::	the message identifier for this tab book [Integer]
    # +opts+::	tar book options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, tgt=nil, sel=0, opts=TABBOOK_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING) # :yields: theTabBook
    end
  end
end

