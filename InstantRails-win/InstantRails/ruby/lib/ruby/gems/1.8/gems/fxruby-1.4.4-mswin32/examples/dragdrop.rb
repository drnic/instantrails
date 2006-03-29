require 'fox14'

include Fox

class DragDropWindow < FXMainWindow
  def initialize(anApp)
    # Initialize base class
    super(anApp, "Drag and Drop", nil, nil, DECOR_ALL, 0, 0, 400, 300)
    
    # Fill main window with canvas
    @canvas = FXCanvas.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @canvas.backColor = "red"
    
    # Enable canvas for drag-and-drop messages
    @canvas.dropEnable
    
    # Handle expose events on the canvas
    @canvas.connect(SEL_PAINT) { |sender, sel, event|
      FXDCWindow.new(@canvas, event) { |dc|
        dc.foreground = @canvas.backColor
        dc.fillRectangle(event.rect.x, event.rect.y, event.rect.w, event.rect.h)
      }
    }

    # Handle left button press
    @canvas.connect(SEL_LEFTBUTTONPRESS) {
      #
      # Capture (grab) the mouse when the button goes down, so that all future
      # mouse events will be reported to this widget, even if those events occur
      # outside of this widget.
      #
      @canvas.grab

      # Advertise which drag types we can offer
      dragTypes = [FXWindow.colorType]
      @canvas.beginDrag(dragTypes)
    }
    
    # Handle mouse motion events
    @canvas.connect(SEL_MOTION) { |sender, sel, event|
      if @canvas.dragging?
        @canvas.handleDrag(event.root_x, event.root_y)
	unless @canvas.didAccept == DRAG_REJECT
	  @canvas.dragCursor = getApp().getDefaultCursor(DEF_SWATCH_CURSOR)
	else
	  @canvas.dragCursor = getApp().getDefaultCursor(DEF_DNDSTOP_CURSOR)
	end
      end
    }

    # Handle SEL_DND_MOTION messages from the canvas
    @canvas.connect(SEL_DND_MOTION) {
      if @canvas.offeredDNDType?(FROM_DRAGNDROP, FXWindow.colorType)
        @canvas.acceptDrop
      end
    }

    # Handle left button release
    @canvas.connect(SEL_LEFTBUTTONRELEASE) {
      @canvas.ungrab
      @canvas.endDrag
    }
    
    # Handle SEL_DND_DROP message from the canvas
    @canvas.connect(SEL_DND_DROP) {
      # Try to obtain the data as color values first
      data = @canvas.getDNDData(FROM_DRAGNDROP, FXWindow.colorType)
      unless data.nil?
        # Update canvas background color
        @canvas.backColor = Fox.fxdecodeColorData(data)
      end
    }

    # Handle request for DND data
    @canvas.connect(SEL_DND_REQUEST) { |sender, sel, event|
      if event.target == FXWindow.colorType
        @canvas.setDNDData(FROM_DRAGNDROP, FXWindow.colorType, Fox.fxencodeColorData(@canvas.backColor))
      end
    }
  end

  def create
    # Create the main window and canvas
    super
    
    # Register the drag type for colors
    FXWindow.colorType = getApp().registerDragType(FXWindow.colorTypeName)

    # Show the main window
    show(PLACEMENT_SCREEN)
  end
end

if __FILE__ == $0
  FXApp.new("DragDrop", "FXRuby") do |theApp|
    DragDropWindow.new(theApp)
    theApp.create
    theApp.run
  end
end

