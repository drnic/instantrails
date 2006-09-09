module Fox
  #
  # The spring widgets, when properly embedded side by side in a horizontal
  # frame or vertical frame widget, behave like a set of connected springs
  # of various lengths.
  #
  # The third and fourth arguments to the FXSpring.new method (+relw+ and +relh+)
  # determine the "length" of the spring. You can also change these settings after
  # the widget is constructed using the FXSpring#relativeWidth and FXSpring#relativeHeight
  # accessor methods.
  # The actual length that you specify is not really
  # important; the only thing that counts is the relative length of one
  # spring widget to that of another, although the length does determine
  # the default size. The special value zero may be given for +relw+ (or +relh+)
  # to cause the spring to calculate its default width (height) normally,
  # just like the FXPacker base class does.
  #
  # In a typical scenario, either the relative width or height is set to
  # zero, an the flag <tt>LAYOUT_FILL_X</tt> or <tt>LAYOUT_FILL_Y</tt> is passed.
  # When placed inside a horizontal frame, the <tt>LAYOUT_FILL_X</tt> together with
  # the relative widths of the springs will cause a fixed width-ratio
  # between the springs.
  #
  # You also can mix normal controls and springs together in a horizontal
  # or vertical frames to provide arbitrary stretchable spacing between
  # widgets; in this case, the springs do not need to have any children.
  # Since the spring widget is derived from the FXPacker layout manager,
  # it provides the same layout behavior as FXPacker.
  #
  class FXSpring < FXPacker
    # Relative width [Integer]
    attr_accessor :relativeWidth
    
    # Relative height [Integer]
    attr_accessor :relativeHeight
    
    #
    # Return an initialized FXSpring instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent widget for this spring [FXComposite]
    # +relw+::	the relative width [Integer]
    # +relh+::	the relative height [Integer]
    # +opts+::	the options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	left-side padding (in pixels) [Integer]
    # +pr+::	right-side padding (in pixels) [Integer]
    # +pt+::	top-side padding (in pixels) [Integer]
    # +pb+::	bottom-side padding (in pixels) [Integer]
    # +hs+::	horizontal spacing (in pixels) [Integer]
    # +vs+::	vertical spacing (in pixels) [Integer]
    #
    def initialize(p, opts=0, relw=0, relh=0, x=0, y=0, w=0, h=0, pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING) # :yields: theSpring
    end
  end
end

