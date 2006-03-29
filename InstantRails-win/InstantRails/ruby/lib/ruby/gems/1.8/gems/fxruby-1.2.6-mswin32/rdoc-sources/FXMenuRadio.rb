module Fox
  #
  # The FXMenuRadio widget is used to change a state in the application from a menu.
  # Menu radio commands may reflect the state of the application by graying out, becoming
  # hidden, or by displaying a bullet.
  #
  # === Events
  #
  # The following messages are sent by FXMenuRadio to its target:
  #
  # +SEL_KEYPRESS+::	sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::	sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::		sent when the command is activated
  #
  class FXMenuRadio < FXMenuCommand

    # Radio button state, one of +TRUE+, +FALSE+ or +MAYBE+
    attr_accessor :check
    
    # Radio background color [FXColor]
    attr_accessor :radioColor

    #
    # Construct a menu radio
    #
    def initialize(p, text, tgt=nil, sel=0, opts=0) # :yields: theMenuRadio
    end
  end
end

