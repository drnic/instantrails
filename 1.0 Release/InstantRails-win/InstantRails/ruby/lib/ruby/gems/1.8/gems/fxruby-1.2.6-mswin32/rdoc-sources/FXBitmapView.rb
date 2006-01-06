module Fox
  #
  # The FXBitmapView widget displays a scrollable view of a bitmap.
  #
  # === Bitmap alignment styles
  #
  # +BITMAPVIEW_NORMAL+::	Normal mode is centered
  # +BITMAPVIEW_CENTER_X+::	Centered horizontally
  # +BITMAPVIEW_LEFT+::		Left-aligned
  # +BITMAPVIEW_RIGHT+::	Right-aligned
  # +BITMAPVIEW_CENTER_Y+::	Centered vertically
  # +BITMAPVIEW_TOP+::		Top-aligned
  # +BITMAPVIEW_BOTTOM+::	Bottom-aligned
  #
  # === Events
  #
  # +SEL_RIGHTBUTTONPRESS+::	sent when the right mouse button goes down; the message data is an FXEvent instance.
  # +SEL_RIGHTBUTTONRELEASE+::	sent when the right mouse button goes up; the message data is an FXEvent instance.
  #
  class FXBitmapView < FXScrollArea
  
    # The bitmap [FXBitmap]
    attr_accessor :bitmap
    
    # The color used for the "on" bits in the bitmap [FXColor]
    attr_accessor :onColor

    # The color used for the "off" bits in the bitmap [FXColor]
    attr_accessor :offColor

    # Current alignment [Integer]
    attr_accessor :alignment

    #
    # Return an initialized FXBitmapView instance.
    #
    def initialize(p, bmp=nil, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theBitmapView
    end
  end
end

