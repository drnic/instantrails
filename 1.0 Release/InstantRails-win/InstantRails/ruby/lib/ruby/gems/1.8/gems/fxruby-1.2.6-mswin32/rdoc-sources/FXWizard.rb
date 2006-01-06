module Fox
  #
  # An FXWizard widget guides the user through a number of panels
  # in a predefined sequence; each step must be completed before
  # moving on to the next step.
  # For example, an FXWizard may be used to install software components,
  # and ask various questions at each step in the installation.
  #
  # === Message identifiers
  #
  # +ID_NEXT+::		Move to the next panel in the wizard
  # +ID_BACK+::		Move to the previous panel in the wizard
  #
  class FXWizard < FXDialogBox
  
    # The button frame [FXHorizontalFrame]
    attr_reader :buttonFrame
    
    # The "Advance" button [FXButton]
    attr_reader :advanceButton
    
    # The "Retreat" button [FXButton]
    attr_reader :retreatButton
    
    # The "Finish" button [FXButton]
    attr_reader :finishButton
    
    # The "Cancel" button [FXButton]
    attr_reader :cancelButton
    
    # The container used as parent for the sub-panels [FXSwitcher]
    attr_reader :container
    
    # The image being displayed [FXImage]
    attr_accessor :image
    
    #
    # Return an initialized, free-floating FXWizard instance.
    #
    def initialize(a, name, image, opts=DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE, x=0, y=0, w=0, h=0, pl=10, pr=10, pt=10, pb=10, hs=10, vs=10) # :yields: theWizard
    end

    #
    # Return an initialized, window-owned FXWizard instance.
    #
    def initialize(owner, name, image, opts=DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE, x=0, y=0, w=0, h=0, pl=10, pr=10, pt=10, pb=10, hs=10, vs=10) # :yields: theWizard
    end

    # Return the number of panels.
    def numPanels; end

    #
    # Bring the child window at _index_ to the top.
    # Raises IndexError if _index_ is out of bounds.
    #
    def currentPanel=(index); end

    #
    # Return the index of the child window currently on top.
    #
    def currentPanel; end
  end
end
