module Fox
  #
  # Main application window
  #
  # === Events
  #
  # The following messages are sent by FXMainWindow to its target:
  #
  # +SEL_CLOSE+::
  #   sent when the user clicks the close button in the upper right-hand
  #   corner of the main window.
  #
  class FXMainWindow < FXTopWindow
    #
    # Construct a main window
    #
    def initialize(app, title, icon=nil, miniIcon=nil, opts=DECOR_ALL, x=0, y=0, width=0, height=0, padLeft=0, padRight=0, padTop=0, padBottom=0, hSpacing=4, vSpacing=4) # :yields: theMainWindow
    end
  end
end
