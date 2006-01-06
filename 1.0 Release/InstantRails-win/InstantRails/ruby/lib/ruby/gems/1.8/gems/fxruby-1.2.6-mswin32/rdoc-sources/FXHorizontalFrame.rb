module Fox
  #
  # The horizontal frame layout manager widget is used to automatically
  # place child-windows horizontally from left-to-right, or right-to-left,
  # depending on the child windows' layout hints.
  #
  class FXHorizontalFrame < FXPacker
    #
    # Return an initialized FXHorizontalFrame instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this horizontal frame [FXComposite]
    # +opts+::	frame options [Integer]
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
    def initialize(p, opts=0, x=0, y=0, w=0, h=0, pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING) # :yields: theHorizontalFrame
    end
  end
end
