module Fox
  #
  # The tri-state button provides a three-state button, which toggles between the
  # on and the off state each time it is pressed. Programmatically, it may also be
  # switched into the +MAYBE+ state. The +MAYBE+ state is useful to signify an
  # "unknown" or "indeterminate" state in the application data.
  #
  class FXTriStateButton < FXToggleButton

    # Maybe text, shown when toggled [String]
    attr_accessor	:maybeText

    # Maybe icon, shown when toggled [FXIcon]
    attr_accessor	:maybeIcon

    # Maybe status line help text, shown when toggled [String]
    attr_accessor	:maybeHelpText

    # Maybe tool tip message, shown when toggled [String]
    attr_accessor	:maybeTipText

    #
    # Return an initialized FXTriStateButton instance.
    #
    # ==== Parameters:
    #
    # +p+::		the parent window for this tri-state button [FXComposite]
    # <tt>text1</tt>::	the text for this tri-state button's first state [String]
    # <tt>text2</tt>::	the text for this tri-state button's second state [String]
    # <tt>text3</tt>::	the text for this tri-state button's third state [String]
    # <tt>icon1</tt>::	the icon, if any, for this tri-state button's first state [FXIcon]
    # <tt>icon2</tt>::	the icon, if any, for this tri-state button's second state [FXIcon]
    # <tt>icon3</tt>::	the icon, if any, for this tri-state button's second state [FXIcon]
    # +tgt+::		the message target, if any, for this tri-state button [FXObject]
    # +sel+::		the message identifier for this tri-state button [Integer]
    # +opts+::		tri-state button options [Integer]
    # +x+::		initial x-position [Integer]
    # +y+::		initial y-position [Integer]
    # +w+::		initial width [Integer]
    # +h+::		initial height [Integer]
    # +pl+::		internal padding on the left side, in pixels [Integer]
    # +pr+::		internal padding on the right side, in pixels [Integer]
    # +pt+::		internal padding on the top side, in pixels [Integer]
    # +pb+::		internal padding on the bottom side, in pixels [Integer]
    #
    def initialize(p, text1, text2, text3, icon1=nil, icon2=nil, icon3=nil, tgt=nil, sel=0, opts=TOGGLEBUTTON_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theTriStateButton
    end
  end
end
