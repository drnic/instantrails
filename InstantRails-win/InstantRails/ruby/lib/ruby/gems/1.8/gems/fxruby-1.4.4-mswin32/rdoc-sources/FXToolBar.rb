module Fox
  #
  # A tool bar widget can be docked in a dock site; it automatically
  # adjusts its orientation based on the orientation of the dock site,
  # and adjusts the layout options accordingly.
  # See FXDockBar widget for more information on the docking behavior.
  #
  class FXToolBar < FXDockBar

    # Docking side, one of +LAYOUT_SIDE_LEFT+, +LAYOUT_SIDE_RIGHT+, +LAYOUT_SIDE_TOP+ or +LAYOUT_SIDE_BOTTOM+ [Integer]
    attr_accessor :dockingSide

    #
    # Return an initialized, floatable FXToolBar instance.
    # Normally, the tool bar is docked under window _p_.
    # When floated, the tool bar can be docked under window _q_, which is
    # typically an FXToolBarShell window.
    #
    # ==== Parameters:
    #
    # +p+::	the "dry dock" window for this tool bar [FXComposite]
    # +q+::	the "wet dock" window for this tool bar [FXComposite]
    # +opts+::	tool bar options [Integer]
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
    def initialize(p, q, opts=LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_FILL_X, x=0, y=0, w=0, h=0, pl=3, pr=3, pt=2, pb=2, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING) # :yields: theToolBar
    end
  
    #
    # Return an initialized, stationary FXToolBar instance.
    # The tool bar can not be undocked.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this tool bar [FXComposite]
    # +opts+::	tool bar options [Integer]
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
    def initialize(p, opts=LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_FILL_X, x=0, y=0, w=0, h=0, pl=3, pr=3, pt=2, pb=2, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING) # :yields: theToolBar
    end
  end
end

