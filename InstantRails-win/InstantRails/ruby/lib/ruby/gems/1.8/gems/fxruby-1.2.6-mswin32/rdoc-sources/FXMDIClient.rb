module Fox
  #
  # The MDI client window manages a number of MDI child windows in
  # a multiple-document interface (MDI) application.
  # MDI child windows usually receive messages from the GUI through
  # delegation via the MDI client, i.e. the MDI client window is set as
  # the target for most GUI commands; the MDI client filters out a few messages
  # and forwards all other messages to the active MDI child.
  # MDI client can arrange the MDI child windows in various ways:-
  # it may maximize one of the MDI child windows, arrange them side-by-side,
  # cascade them, or iconify them.
  # MDI child windows are notified about changes in the active MDI child
  # window by the MDI client.
  #
  # === Events
  #
  # The following messages are sent by FXMDIClient to its target:
  #
  # +SEL_CHANGED+::
  #   sent when the active child changes; the message data is a reference to the new active child window (or +nil+ if there is none)
  #
  class FXMDIClient < FXScrollArea
  
    # Active MDI child window, or +nil+ if none [FXMDIChild].
    attr_accessor :activeChild
  
    # Cascade offset X [Integer]
    attr_accessor :cascadeX
  
    # Cascade offset Y [Integer]
    attr_accessor :cascadeY

    # Construct MDI Client window
    def initialize(p, opts=0, x=0, y=0, w=0, h=0) # :yields: theMDIClient
    end

    # Get first MDI Child
    def getMDIChildFirst(); end
  
    # Get last MDI Child
    def getMDIChildLast(); end
  
    #
    # Pass message to all MDI windows, stopping when one of
    # the MDI windows fails to handle the message.
    #
    def forallWindows(sender, sel, ptr); end
  
    #
    # Pass message once to all MDI windows with the same document,
    # stopping when one of the MDI windows fails to handle the message.
    #
    def forallDocuments(sender, sel, ptr); end

    #
    # Pass message to all MDI Child windows whose target is _document_,
    # stopping when one of the MDI windows fails to handle the message.
    #
    def forallDocWindows(document, sender, sel, ptr); end
  
    #
    # Set active MDI child window for this MDI client to _child_.
    #
    def setActiveChild(child=nil, notify=true); end
  end
end

