require 'fox16'

include Fox

class RulerViewExample < FXMainWindow
  def initialize(app)
    # Initialize base class
    super(app, "Ruler View", nil, nil, DECOR_ALL, 0, 0, 400, 400)
    
    # Construct a ruler view inside
    ruler_view = FXRulerView.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # And put some content inside that
    contents = FXText.new(ruler_view, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    contents.text = "This is a test."
  end
end

if __FILE__ == $0
  FXApp.new do |app|
    main = RulerViewExample.new(app)
    app.create
    main.show(PLACEMENT_SCREEN)
    app.run
  end
end

