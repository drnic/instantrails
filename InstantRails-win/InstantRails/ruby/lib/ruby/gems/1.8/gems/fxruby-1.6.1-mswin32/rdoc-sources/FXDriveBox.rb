module Fox
  #
  # Drive box
  #
  # === Events
  #
  # The following messages are sent by FXDriveBox to its target:
  #
  # +SEL_CHANGED+::	sent when the current item changes; the message data is the current drive
  # +SEL_COMMAND+::	sent when a new item is selected from the list; the message data is the drive
  #
  class FXDriveBox < FXListBox

    # Current drive [String]
    attr_accessor :drive
    
    # File associations [FXFileDict]
    attr_accessor :associations

    # Returns an initialized FXDriveBox instance
    def initialize(p, tgt=nil, sel=0, opts=FRAME_SUNKEN|FRAME_THICK|LISTBOX_NORMAL, x=0, y=0, w=0, h=0, pl=DEFAULT_PAD, pr=DEFAULT_PAD, pt=DEFAULT_PAD, pb=DEFAULT_PAD) # :yields: theDriveBox
    end

    #
    # Set current drive, where _drive_ is a string.
    # Returns +true+ on success, +false+ on failure.
    #
    def setDrive(drive); end
    
    #
    # Return current drive as a string.
    #
    def getDrive(); end
    
    #
    # Change file associations, where _assoc_ is an FXFileDict instance.
    #
    def setAssociations(assoc); end
    
    #
    # Return file associations (an FXFileDict instance).
    #
    def getAssociations(); end
  end
end

