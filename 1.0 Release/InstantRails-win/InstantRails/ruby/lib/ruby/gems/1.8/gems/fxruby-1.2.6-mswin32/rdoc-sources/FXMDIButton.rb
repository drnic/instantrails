module Fox
  #
  # MDI Delete button
  #
  class FXMDIDeleteButton < FXButton
    #
    # Constructor
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_RAISED, x=0, y=0, w=0, h=0) # :yields: theMDIDeleteButton
    end
  end

  #
  # MDI Restore button
  #
  class FXMDIRestoreButton < FXButton
    #
    # Constructor
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_RAISED, x=0, y=0, w=0, h=0) # :yields: theMDIRestoreButton
    end
  end

  #
  # MDI Maximize button
  #
  class FXMDIMaximizeButton < FXButton
    #
    # Constructor
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_RAISED, x=0, y=0, w=0, h=0) # :yields: theMDIMaximizeButton
    end
  end

  #
  # MDI Minimize button
  #
  class FXMDIMinimizeButton < FXButton
    #
    # Constructor
    #
    def initialize(p, tgt=nil, sel=0, opts=FRAME_RAISED, x=0, y=0, w=0, h=0) # :yields: theMDIMinimizeButton
    end
  end

  #
  # MDI Window button
  #
  class FXMDIWindowButton < FXMenuButton
    #
    # Constructor
    #
    def initialize(p, pup, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theMDIWindowButton
    end
  end

  #
  # MDI Window Menu
  #
  class FXMDIMenu < FXMenuPane
    #
    # Construct MDI menu
    #
    def initialize(owner, tgt=nil); end
  end
end

