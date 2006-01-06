#!/usr/bin/env ruby
# ratio.rb  
# Translated from FOX C++ version to Ruby (Dec 2004) by Brett Hallett.
# Demonstrates the use of the FXSpring method to retain size ratios between widgets when form is resized.
#

require 'fox12'
require 'fox12/colors'

include Fox

class MainWindow < FXMainWindow
  
  def initialize(app)
	 # Initialize base class first
    super(app, 'Ratio', nil, nil, DECOR_ALL, 0, 0, 400, 200, 8, 8, 8, 8, 6, 6)

    # Add quit button and connect it to application
    FXButton.new(self, "&Quit", nil, app, FXApp::ID_QUIT, FRAME_RAISED|FRAME_THICK|LAYOUT_SIDE_BOTTOM|LAYOUT_CENTER_X, 0, 0, 0, 0, 20, 20, 2, 2)

    # Label above it
    FXLabel.new(self, "FXSpring can be used to keep widgets at fixed size ratios.\n\nResize the window to see how it behaves!", nil, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Layout manager to place the springs
    horz = FXHorizontalFrame.new(self, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

	 # First spring is set to behave normally in Y direction,
	 # but to have a ratio 1 for the X direction
	 FXSpring.new(horz, LAYOUT_FILL_X|LAYOUT_FILL_Y, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0) do |spring1|
	   FXLabel.new(spring1, "1", nil, LAYOUT_FILL_X|LAYOUT_FILL_Y) do |label1|
	     label1.backColor = FXColor::Red
      end
    end

    # Second spring has ratio 2 in the X direction
    FXSpring.new(horz, LAYOUT_FILL_X|LAYOUT_FILL_Y, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0) do |spring2|
      FXLabel.new(spring2, "2", nil, LAYOUT_FILL_X|LAYOUT_FILL_Y) do |label2|
        label2.backColor = FXColor::Green
      end
    end

    # Third spring has ratio 3 in the X direction
    FXSpring.new(horz, LAYOUT_FILL_X|LAYOUT_FILL_Y, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0) do |spring3|
      FXLabel.new(spring3, "3", nil, LAYOUT_FILL_X|LAYOUT_FILL_Y) do |label3|
        label3.backColor = FXColor::Blue
      end
    end
  end

  def create
    super 
    show(PLACEMENT_SCREEN) 
  end # create 

end  # class MainWindow 

if __FILE__ == $0
  # Construct an application 
  FXApp.new('Smithy', 'Max') do |theApp|

    # Construct the main window  
    MainWindow.new(theApp) 

    # Create and show the application windows  
    theApp.create 

    # Run the application  
    theApp.run
  end
end
