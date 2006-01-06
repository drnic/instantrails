module Fox
  #
  # Shutter item
  #
  # === Message identifiers
  #
  # +ID_SHUTTERITEM_BUTTON+::	x
  #
  class FXShutterItem < FXVerticalFrame
    #
    # The button for this shutter item [FXButton]
    #
    attr_reader :button
    
    # The contents for this shutter item [FXVerticalFrame]
    attr_reader :content
    
    # Status line help text for this shutter item [String]
    attr_accessor :helpText

    # Tool tip message for this shutter item [String]
    attr_accessor :tipText

    #
    # Return an initialized FXShutterItem instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent shutter for this shutter item [FXShutter]
    # +text+::	the text, if any [String]
    # +icon+::	the icon, if any [FXIcon]
    # +opts+::	options [Integer]
    # +x+::	initial x-position, when the +LAYOUT_FIX_X+ layout hint is in effect [Integer]
    # +y+::	initial y-position, when the +LAYOUT_FIX_Y+ layout hint is in effect [Integer]
    # +w+::	initial width, when the +LAYOUT_FIX_WIDTH+ layout hint is in effect [Integer]
    # +h+::	initial height, when the +LAYOUT_FIX_HEIGHT+ layout hint is in effect [Integer]
    # +pl+::	internal padding on the left side, in pixels [Integer]
    # +pr+::	internal padding on the right side, in pixels [Integer]
    # +pt+::	internal padding on the top side, in pixels [Integer]
    # +pb+::	internal padding on the bottom side, in pixels [Integer]
    # +hs+::	horizontal spacing between widgets, in pixels [Integer]
    # +vs+::	vertical spacing between widgets, in pixels [Integer]
    #
    def initialize(p, text="", icon=nil, opts=0, x=0, y=0, w=0, h=0, pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING) # :yields: theShutterItem
    end
  end

  #
  # Shutter control
  #
  # === Events
  #
  # The following messages are sent by FXShutter to its target:
  #
  # +SEL_COMMAND+::
  #   sent whenever a new shutter item is opened; the message data is an integer
  #   indicating the new currently displayed shutter item.
  #
  # === Message identifiers
  #
  # +ID_SHUTTER_TIMEOUT+::	x
  # +ID_OPEN_SHUTTERITEM+::	x
  # +ID_OPEN_FIRST+::		x
  # +ID_OPEN_LAST+::		x
  #
  class FXShutter < FXVerticalFrame
  
    #
    # The currently displayed shutter item (a zero-based index) [Integer]
    #
    attr_accessor :current

    #
    # Return an initialized FXShutter instance.
    #
    # ==== Parameters:
    #
    # +p+::	the parent window for this shutter [FXComposite]
    # +tgt+::	the message target, if any, for this shutter [FXObject]
    # +sel+::	the message identifier for this shutter [Integer]
    # +opts+::	shutter options [Integer]
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
    def initialize(p, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0, pl=DEFAULT_SPACING, pr=DEFAULT_SPACING, pt=DEFAULT_SPACING, pb=DEFAULT_SPACING, hs=DEFAULT_SPACING, vs=DEFAULT_SPACING) # :yields: theShutter
    end
  end
end

