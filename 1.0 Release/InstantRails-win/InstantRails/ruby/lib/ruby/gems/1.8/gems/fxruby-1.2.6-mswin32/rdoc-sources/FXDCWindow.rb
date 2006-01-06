module Fox
  #
  # A window device context allows drawing into an FXDrawable, such as an
  # on-screen window (i.e. FXWindow and itsderivatives) or an off-screen image (FXImage
  # and its derivatives).
  # Because certain hardware resources are locked down, only one FXDCWindow may be 
  # locked on a drawable at any one time.
  #
  class FXDCWindow < FXDC
    #
    # Construct for painting in response to expose; this sets the clip rectangle to the exposed rectangle.
    # If an optional code block is provided, the new device context will be passed into the block as an
    # argument and #end will be called automatically when the block terminates.
    #
    def initialize(drawable, event)	# :yields: dc
    end

    #
    # Construct for normal drawing; this sets clip rectangle to the whole drawable.
    # If an optional code block is provided, the new device context will be passed into the block as an
    # argument and #end will be called automatically when the block terminates.
    #
    def initialize(drawable)		# :yields: dc
    end

    #
    # Lock in a drawable surface.
    #
    def begin(drawable) ; end

    #
    # Unlock the drawable surface.
    #
    def end() ; end
  end
end

