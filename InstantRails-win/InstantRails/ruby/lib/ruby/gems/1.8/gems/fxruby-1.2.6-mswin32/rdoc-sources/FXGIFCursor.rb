module Fox
  #
  # GIF Cursor class.
  #
  class FXGIFCursor < FXCursor
    #
    # Return an initialized FXGIFCursor instance.
    #
    def initialize(a, pix, hx=-1, hy=-1) # :yields: theGIFCursor
    end
  end  
  
  #
  # Save a GIF image to a stream.
  # Returns +true+ on success, +false+ on failure.
  #
  # ==== Parameters:
  #
  # +store+::	stream to which to write the image data [FXStream]
  # +data+::	the image pixel data [String]
  # +transp+::	transparency color [FXColor]
  # +width+::	width [Integer]
  # +height+::	height [Integer]
  #
  def fxsaveGIF(store, data, transp, width, height); end
  
  #
  # Load a GIF file from a stream.
  # If successful, returns an array containing the image pixel data (as a
  # String), the transparency color, the image width and the image height.
  # If it fails, the function returns +nil+.
  #
  # ==== Parameters:
  #
  # +store+::	stream from which to read the file data [FXStream]
  #
  def fxloadGIF(store); end
end
