module Fox
  #
  # Option Menu Button
  #
  # === Events
  #
  # The following messages are sent by FXOption to its target:
  #
  # +SEL_KEYPRESS+::		sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::		sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::		sent when this option is clicked; the message data is an FXEvent instance.
  #
  class FXOption < FXLabel
    #
    # Returns an initialized FXOption instance.
    #
    def initialize(p, text, ic=nil, tgt=nil, sel=0, opts=JUSTIFY_NORMAL|ICON_BEFORE_TEXT, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theOption
    end
  end

  #
  # Option Menu
  #
  # === Events
  #
  # The following messages are sent by FXOptionMenu to its target:
  #
  # +SEL_KEYPRESS+::		sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::		sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONPRESS+::	sent when the left mouse button goes down; the message data is an FXEvent instance.
  # +SEL_LEFTBUTTONRELEASE+::	sent when the left mouse button goes up; the message data is an FXEvent instance.
  #
  class FXOptionMenu < FXLabel
  
    # The current option, or +nil+ if none [FXOption]
    attr_accessor :current
    
    # The current option number, or -1 if none [Integer]
    attr_accessor :currentNo
    
    # The pane which will be popped up [FXPopup]
    attr_accessor :menu
    
    #
    # Returns an initialized FXOptionMenu instance.
    #
    def initialize(p, pup=nil, opts=JUSTIFY_NORMAL|ICON_BEFORE_TEXT, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theOptionMenu
    end
  
    #
    # Set the current option.
    #
    def setCurrent(win, notify=false); end
    
    #
    # Return a reference to the current option (an FXOption instance).
    #
    def getCurrent(); end
  
    #
    # Set the current option number.
    #
    def setCurrentNo(no, notify=false); end
    
    #
    # Get the current option number.
    #
    def getCurrentNo(); end

    # Return +true+ if popped up
    def popped?; end
  end
end

