module Fox
  #
  # A bitmap is a rectangular array of pixels.
  # It supports two representations of these pixels: a client-side pixel buffer,
  # and a server-side pixmap which is stored in an organization directly compatible
  # with the screen, for fast drawing onto the device. The server-side representation
  # is not directly accessible from the current process at it lives in the process
  # of the X server or GDI (on Microsoft Windows).
  # The client-side pixel array is of size height x (width+7)/8 bytes; in other
  # words, 8 pixels packed into a single byte, starting with bit zero on the left.
  # 
  # === Image rendering hints
  #
  # +BITMAP_KEEP+::	Keep pixel data in client
  # +BITMAP_OWNED+::	Pixel data is owned by image
  # +BITMAP_SHMI+::	Using shared memory image
  # +BITMAP_SHMP+::	Using shared memory pixmap
  #
  class FXBitmap < FXDrawable
    #
    # Return an initialized FXBitmap instance.
    # If a client-side pixel buffer (the _pixels_ argument) has been specified,
    # the bitmap does not own that pixel buffer unless the +BITMAP_OWNED+ flag
    # is set. If the +BITMAP_OWNED+ flag _is_ set, but a +nil+ value for _pixels_
    # is passed in, a pixel buffer will be automatically created and will be
    # owned by the bitmap. The flags +BITMAP_SHMI+ and +BITMAP_SHMP+ may be
    # specified for large bitmaps to instruct FXBitmap#render to use shared
    # memory to communicate with the server.
    #
    def initialize(app, pixels=nil, opts=0, width=1, height=1) # :yields: theBitmap
    end

    # Return the pixel data.
    def data; end
    
    # Return the option flags.
    def options; end
    
    # Set the options.
    def options=(opts); end

    # Render the server-side representation of the bitmap from the client-side pixels.
    def render() ; end
    
    #
    # Release the client-side pixels buffer and free it if it was owned.
    # If it is not owned, the image just forgets about the buffer.
    #
    def release(); end

    # Save pixel data only
    def savePixels(stream); end
    
    # Load pixel data from a stream
    def loadPixels(stream); end

    # Get pixel state (either +true+ or +false+) at (_x_, _y_)
    def getPixel(x, y) ; end

    # Change pixel at (_x_, _y_), where _color_ is either +true+ or +false+.
    def setPixel(x, y, color) ; end
    
    # Rescale pixels to the specified width and height.
    def scale(w, h); end
    
    # Mirror the bitmap horizontally and/or vertically
    def mirror(horizontal, vertical); end
    
    # Rotate bitmap by _degrees_ degrees (counter-clockwise)
    def rotate(degrees); end
    
    # Crop bitmap to given rectangle
    def crop(x, y, w, h); end
    
    # Fill bitmap with uniform value
    def fill(color); end
  end
end