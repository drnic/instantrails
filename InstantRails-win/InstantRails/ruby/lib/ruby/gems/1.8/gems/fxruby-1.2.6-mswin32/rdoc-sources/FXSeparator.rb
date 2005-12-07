module Fox
  #
  # Horizontal separator
  #
  # === Separator options
  #
  # +SEPARATOR_NONE+::		Nothing visible
  # +SEPARATOR_GROOVE+::	Etched-in looking groove
  # +SEPARATOR_RIDGE+::		Embossed looking ridge
  # +SEPARATOR_LINE+::		Simple line
  #
  class FXHorizontalSeparator < FXFrame
    #
    # Return an initialized FXHorizontalSeparator instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent widget for this separator [FXComposite]
    # +opts+::	the options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, opts=SEPARATOR_GROOVE|LAYOUT_FILL_X, x=0, y=0, w=0, h=0, pl=1, pr=1, pt=0, pb=0) # :yields: theHorizontalSeparator
    end
  end

  #
  # Vertical separator
  #
  # === Separator options
  #
  # +SEPARATOR_NONE+::		Nothing visible
  # +SEPARATOR_GROOVE+::	Etched-in looking groove
  # +SEPARATOR_RIDGE+::		Embossed looking ridge
  # +SEPARATOR_LINE+::		Simple line
  #
  class FXVerticalSeparator < FXFrame
    #
    # Return an initialized FXVerticalSeparator instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent widget for this separator [FXComposite]
    # +opts+::	the options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, opts=SEPARATOR_GROOVE|LAYOUT_FILL_Y, x=0, y=0, w=0, h=0, pl=0, pr=0, pt=1, pb=1) # :yields: theVerticalSeparator
    end
  end
end

