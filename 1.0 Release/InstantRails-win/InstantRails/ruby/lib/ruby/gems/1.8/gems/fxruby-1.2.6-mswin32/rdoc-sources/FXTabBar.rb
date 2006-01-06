module Fox
  #
  # The FXTabBar layout manager arranges tab items side by side,
  # and raises the active tab item above the neighboring tab items.
  # In a the horizontal arrangement, the tab bar can have the tab
  # items on the top or on the bottom.  In the vertical arrangement,
  # the tabs can be on the left or on the right.
  #
  # === Events
  #
  # The following messages are sent by FXTabBar to its target:
  #
  # +SEL_COMMAND+::
  #   sent whenever the current tab item changes;
  #   the message data is an integer indicating the new current tab item's index.
  #
  # === Tab book options
  #
  # +TABBOOK_TOPTABS+::		Tabs on top (default)
  # +TABBOOK_BOTTOMTABS+::	Tabs on bottom
  # +TABBOOK_SIDEWAYS+::	Tabs on left
  # +TABBOOK_LEFTTABS+::	Tabs on left
  # +TABBOOK_RIGHTTABS+::	Tabs on right
  # +TABBOOK_NORMAL+::		same as <tt>TABBOOK_TOPTABS</tt>
  #
  # === Message identifiers
  #
  # +ID_OPEN_ITEM+::	Sent from one of the FXTabItems
  # +ID_OPEN_FIRST+::	Switch to the first panel
  # +ID_OPEN_SECOND+::	x
  # +ID_OPEN_THIRD+::	x
  # +ID_OPEN_FOURTH+::	x
  # +ID_OPEN_FIFTH+::	x
  # +ID_OPEN_SIXTH+::	x
  # +ID_OPEN_SEVENTH+::	x
  # +ID_OPEN_EIGHTH+::	x
  # +ID_OPEN_NINETH+::	x
  # +ID_OPEN_TENTH+::	x
  # +ID_OPEN_LAST+::	x
  #
  class FXTabBar < FXPacker
    # Currently active tab item's index [Integer]
    attr_accessor :current
    
    # Tab bar style [Integer]
    attr_accessor :tabStyle

    #
    # Return an initialized FXTabBar instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this tar bar [FXComposite]
    # +tgt+::	the message target, if any, for this tar bar [FXObject]
    # +sel+::	the message identifier for this tab bar [Integer]
    # +opts+::	tar bar options [Integer]
    # +x+::	initial x-position [Integer]
    # +y+::	initial y-position [Integer]
    # +w+::	initial width [Integer]
    # +h+::	initial height [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, tgt=nil, sel=0, opts=TABBOOK_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING) # :yields: theTabBar
    end

    #
    # Set the current tab item to the one at _index_.
    # If _notify_ is +true+, a +SEL_COMMAND+ message is sent to the tab bar's message target
    #
    def setCurrent(index, notify=false); end
  end
end

