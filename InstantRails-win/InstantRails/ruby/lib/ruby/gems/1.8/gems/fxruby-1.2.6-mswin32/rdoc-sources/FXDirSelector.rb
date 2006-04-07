module Fox
  #
  # Directory selection widget
  #
  # === Message identifiers
  #
  # +ID_DIRNAME+::	x
  # +ID_DIRLIST+::	x
  # +ID_DRIVEBOX+::	x
  #
  class FXDirSelector < FXPacker
  
    # The "Accept" button [FXButton]
    attr_reader :acceptButton
    
    # The "Cancel" button [FXButton]
    attr_reader :cancelButton
    
    # Directory [String]
    attr_accessor :directory
    
    # Directory list style [Integer]
    attr_accessor :dirBoxStyle

    # Return an initialized FXDirSelector instance
    def initialize(p, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theDirSelector
    end
  end
end

