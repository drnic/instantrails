module Fox
  #
  # Toolbar control.
  #
  # === Message identifiers
  #
  # +ID_UNDOCK+::	Undock the tool bar
  # +ID_DOCK_TOP+::	Dock on the top
  # +ID_DOCK_BOTTOM+::	Dock on the bottom
  # +ID_DOCK_LEFT+::	Dock on the left
  # +ID_DOCK_RIGHT+::	Dock on the right
  # +ID_TOOLBARGRIP+::	Notifications from tool bar grip
  #
  class FXToolBar < FXPacker

    # Parent window when the tool bar is docked [FXComposite]
    attr_reader	:dryDock
    
    # Parent window when the tool bar is undocked (or "floating") [FXComposite]
    attr_reader	:wetDock
    
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

    #
    # Dock the bar against the given _side_, after some other widget.
    # However, if _after_ is -1, it will be docked as the innermost toolbar just before
    # the work-area, while if _after_ is 0, if will be docked as the outermost toolbar.
    #
    # ==== Parameters:
    #
    # +side+::
    #   side of the parent window against which to dock the tool bar, one of
    #   +LAYOUT_SIDE_TOP+, +LAYOUT_SIDE_BOTTOM+, +LAYOUT_SIDE_LEFT+ or +LAYOUT_SIDE_RIGHT+ [Integer].
    # +after+::
    #   sibling window (i.e. inside the parent) after which to dock this tool bar [FXWindow].
    #   Also see exceptions described above for the cases when _after_ is 0 or -1.
    #
    def dock(side=LAYOUT_SIDE_TOP, after=-1); end
    
    #
    # Undock or "float" the toolbar.
    # The initial position of the wet dock is a few pixels
    # below and to the right of the original docked position.
    #
    def undock; end

    #
    # Set parent when docked.
    # If it was already docked, reparent under the new docking window.
    #
    # ==== Parameters:
    #
    # +p+::	new "dry dock" parent window for this tool bar [FXComposite]
    #
    def setDryDock(p); end

    #
    # Set parent when floating.
    # If it was already undocked, then reparent under the new floating window.
    #
    # ==== Parameters:
    #
    # +q+::	new "wet dock" parent window for this tool bar [FXComposite]
    #
    def setWetDock(q); end

    #
    # Return +true+ if toolbar is docked
    #
    def docked? ; end
  end
end

