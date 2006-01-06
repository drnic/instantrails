module Fox
  #
  # Directory selection dialog
  #
  class FXDirDialog < FXDialogBox
  
    # Directory [String]
    attr_accessor :directory
    
    # Directory list style [Integer]
    attr_accessor :dirBoxStyle
    
    # Returns an initialized FXDirDialog instance.
    def initialize(owner, name, opts=0, x=0, y=0, w=500, h=300) # :yields: theDirDialog
    end
  end
end

