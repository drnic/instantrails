module Fox
  #
  # A Separator widget is used to draw a horizontal or vertical divider between
  # groups of controls.  It is purely decorative.  The separator may be drawn
  # in various styles as determined by the SEPARATOR_NONE, SEPARATOR_GROOVE,
  # SEPARATOR_RIDGE, and SEPARATOR_LINE options.  Since its derived from Frame,
  # it can also have the frame's border styles.
  #
  # === Separator options
  #
  # +SEPARATOR_NONE+::		Nothing visible
  # +SEPARATOR_GROOVE+::	Etched-in looking groove
  # +SEPARATOR_RIDGE+::		Embossed looking ridge
  # +SEPARATOR_LINE+::		Simple line
  #
  class FXSeparator < FXFrame

    # Separator style, one of SEPARATOR_NONE, SEPARATOR_GROOVE, SEPARATOR_RIDGE or SEPARATOR_LINE [Integer]
    attr_accessor :separatorStyle

    # Return an initialized FXSeparator instance.
    def initialize(p, opts=SEPARATOR_GROOVE|LAYOUT_FILL_X, x=0, y=0, w=0, h=0, pl=0, pr=0, pt=0, pb=0) # :yields: theSeparator
    end
  end
    
  #
  # Horizontal separator
  #
  class FXHorizontalSeparator < FXSeparator
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
  class FXVerticalSeparator < FXSeparator
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

