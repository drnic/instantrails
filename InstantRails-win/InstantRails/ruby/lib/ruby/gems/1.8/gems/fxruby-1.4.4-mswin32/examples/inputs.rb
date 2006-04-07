#!/usr/bin/env ruby

require 'fox14'

include Fox

class InputHandlerWindow < FXMainWindow

  def initialize(app)
    # Initialize base class first
    super(app, "Input Handlers Test", nil, nil, DECOR_ALL, 0, 0, 400, 300)

    # Text area plus a button
    commands = FXHorizontalFrame.new(self, LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
    FXLabel.new(commands, "Command:")
    @cmdInput = FXTextField.new(commands, 30,
      nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X) 
    @cmdInput.connect(SEL_COMMAND, method(:onCmdText))
    FXHorizontalSeparator.new(self, LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
    textFrame = FXVerticalFrame.new(self,
        FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    # Output will be displayed in a multiline text area
    @cmdOutput = FXText.new(textFrame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)

    # Initialize the pipe
    @pipe = nil
  end

  # Create and show the main window
  def create
    super
    show(PLACEMENT_SCREEN)
  end

  # Remove previous input (if any)
  def closePipe
    if @pipe
      getApp().removeInput(@pipe, INPUT_READ|INPUT_EXCEPT)
      @pipe = nil
    end
  end
  
  def onCmdText(sender, sel, ptr)
    # Stop previous command
    closePipe

    # Clean up the output window
    @cmdOutput.text = ""

    # Open a new pipe
    @pipe = IO.popen(@cmdInput.text)

    # Register input callbacks and return
    getApp().addInput(@pipe, INPUT_READ|INPUT_EXCEPT) { |sender, sel, ptr|
      case SELTYPE(sel)
        when SEL_IO_READ
	  text = @pipe.read
	  if text
            @cmdOutput.appendText(text)
	  else
	    closePipe
	  end
        when SEL_IO_EXCEPT
#         puts 'onPipeExcept'
      end
    }
    return 1
  end
end

if $0 == __FILE__
  # Construct an application
  application = FXApp.new('InputHandler', 'FoxTest')

  # Construct the main window
  InputHandlerWindow.new(application)

  # Create and show the application windows
  application.create

  # Run the application
  application.run
end
