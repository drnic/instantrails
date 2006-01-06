module Fox
  #
  # A picker button allows you to identify an arbitrary
  # location on the screen.
  #
  # === Events
  #
  # The following messages are sent by FXPicker to its target:
  #
  # +SEL_CHANGED+::
  #   sent continuously while the position is changing; the message data is an
  #   FXPoint instance indicating the current root window position of the mouse
  #   pointer.
  # +SEL_COMMAND+::
  #   sent when the left mouse button is clicked the second time (i.e. to
  #   "pick" a position); the message data is an FXPoint instance indicating
  #   the picked position in root window coordinates.
  #
  class FXPicker < FXButton
    #
    # Constructor
    #
    def initialize(p, text, ic=nil, tgt=nil, sel=0, opts=BUTTON_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: thePicker
    end
  end
end

