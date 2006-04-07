module Fox
  #
  # The FXImageView widget displays a scrollable view of an image.
  #
  # === Image alignment styles
  #
  # +IMAGEVIEW_NORMAL+::	Normal mode is centered
  # +IMAGEVIEW_CENTER_X+::	Centered horizontally
  # +IMAGEVIEW_LEFT+::		Left-aligned
  # +IMAGEVIEW_RIGHT+::		Right-aligned
  # +IMAGEVIEW_CENTER_Y+::	Centered vertically
  # +IMAGEVIEW_TOP+::		Top-aligned
  # +IMAGEVIEW_BOTTOM+::	Bottom-aligned
  #
  # === Events
  #
  # +SEL_RIGHTBUTTONPRESS+::	sent when the right mouse button goes down; the message data is an FXEvent instance.
  # +SEL_RIGHTBUTTONRELEASE+::	sent when the right mouse button goes up; the message data is an FXEvent instance.
  #
  class FXImageView < FXScrollArea
  
    # The image [FXImage]
    attr_accessor :image
    
    # Current alignment [Integer]
    attr_accessor :alignment

    #
    # Return an initialized FXImageView instance.
    #
    def initialize(p, img=nil, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theImageView
    end
  end
end

