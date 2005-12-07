module Fox
  #
  # A toolbar tab is used to collapse or uncollapse a sibling
  # widget. The sibling affected is the widget immediately following
  # the toolbar tab or, if the toolbar tab is the last widget in the list,
  # the widget immediately preceding the toolbar tab.
  # Typically, the toolbar tab is paired with just one sibling widget
  # inside a paired container, e.g.
  #
  #     FXHorizontalFrame.new(...) do |p|
  #       FXToolBarTab.new(p)
  #       FXLabel.new(p, "Hideable label", nil, LAYOUT_FILL_X)
  #     end
  #
  # === Events
  #
  # The following messages are sent by FXToolBarTab to its target:
  #
  # +SEL_KEYPRESS+::	Sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::	Sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::	Sent after the toolbar tab is collapsed (or uncollapsed). The message data indicates the new collapsed state (i.e. it's +true+ if the toolbar tab is now collapsed, +false+ if it is now uncollapsed).
  #
  # === Toolbar tab styles
  #
  # +TOOLBARTAB_HORIZONTAL+::		Default is for horizontal toolbar
  # +TOOLBARTAB_VERTICAL+::		For vertical toolbar
  #
  # === Message identifiers
  # 
  # +ID_COLLAPSE+::					Collapse the toolbar tab
  # +ID_UNCOLLAPSE+::				Uncollapse the toolbar tab
  #
  class FXToolBarTab < FXFrame

    # The tab style [Integer]
    attr_accessor :tabStyle

    # The active color [FXColor]
    attr_accessor :activeColor

    #
    # Return an initialized FXToolBarTab instance.
    #
    # ==== Parameters:
    #
    # +p+::		the parent window for this toolbar tab [FXWindow]
    # +tgt+::	the message target [FXObject]
    # +sel+::	the message identifier [Integer]
    # +opts+::	the options [Integer]
    # +x+::		x-coordinate of window upper left corner [Integer]
    # +y+::		y-coordinate of window upper left corner [Integer]
    # +w+::		window width [Integer]
    # +h+::		window height [Integer]
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_RAISED, x=0, y=0, w=0, h=0) # :yield: theToolBarTab
	 end

    #
    # Collapse (if _c_ is +true+) or uncollapse the toolbar.
    #
    def collapse(c=true); end
  
    #
    # Return +true+ if the toolbar is collapsed, +false+ otherwise.
    #
    def collapsed?; end
  end
end

