module Fox
  #
  # The dock handler exists as a common base class for tool bar grip
  # and dock title.  
  #
  class FXDockHandler < FXFrame
    # Status line help text [String]
    attr_accessor :helpText
    
    # Tool tip text [String]
    attr_accessor :tipText
    
    #
    # Return an initialized FXDockHandler instance.
    #
    def initialize(p, tgt, sel, opts, x, y, w, h, pl, pr, pt, pb) # :yields: aDockHandler
    end
  end
end
