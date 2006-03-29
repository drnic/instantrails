require 'fox14'

include Fox

class DropSite < FXMainWindow
  def initialize(anApp)
    # Initialize base class
    super(anApp, "Drop Site", nil, nil, DECOR_ALL, 0, 0, 400, 300)
    
    # Fill main window with canvas
    @canvas = FXCanvas.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # Handle expose events on the canvas
    @canvas.connect(SEL_PAINT) { |sender, sel, event|
      FXDCWindow.new(@canvas, event) { |dc|
        dc.foreground = @canvas.backColor
        dc.fillRectangle(event.rect.x, event.rect.y, event.rect.w, event.rect.h)
      }
    }

    # Enable canvas for drag-and-drop messages
    @canvas.dropEnable
    
    # Handle SEL_DND_MOTION messages from the canvas
    @canvas.connect(SEL_DND_MOTION) {
      if @canvas.offeredDNDType?(FROM_DRAGNDROP, FXWindow.colorType)
        @canvas.acceptDrop
      end
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
  FXApp.new("DropSite", "FXRuby") do |theApp|
    DropSite.new(theApp)
    theApp.create
    theApp.run
  end
end

