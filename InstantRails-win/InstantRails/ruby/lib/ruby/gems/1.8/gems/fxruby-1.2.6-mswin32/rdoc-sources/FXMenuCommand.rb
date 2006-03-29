module Fox
  #
  # The FXMenuCommand widget is used to invoke a command in the
  # application from a menu.  Menu commands may reflect
  # the state of the application by graying out or becoming hidden.
  #
  # === Events
  #
  # The following messages are sent by FXMenuCommand to its target:
  #
  # +SEL_KEYPRESS+::	sent when a key goes down; the message data is an FXEvent instance.
  # +SEL_KEYRELEASE+::	sent when a key goes up; the message data is an FXEvent instance.
  # +SEL_COMMAND+::		sent when the command is activated
  #
  class FXMenuCommand < FXMenuCaption

    # Accelerator text [String]
    attr_accessor :accelText

    #
    # Construct a menu command
    #
    def initialize(p, text, ic=nil, tgt=nil, sel=0, opts=0) # :yields: theMenuCommand
    end
  end
end

