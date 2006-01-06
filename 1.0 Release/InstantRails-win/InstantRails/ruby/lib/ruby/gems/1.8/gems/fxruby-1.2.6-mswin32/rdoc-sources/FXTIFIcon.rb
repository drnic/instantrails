module Fox
  #
  # Tagged Image File Format (TIFF) Icon
  #
  class FXTIFIcon < FXIcon
    # Codec setting [Integer]
    attr_accessor :codec

    #
    # Return an initialized FXTIFIcon instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in TIFF file format [String]
    # +clr+::	transparency color [FXColor]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, clr=0, opts=0, w=1, h=1) # :yields: theTIFIcon
    end
  end
  
  #
  # Load a TIFF file from a stream.
  # If successful, returns an array containing the image pixel data (as a
  # String), transparency color, width, height and codec setting.
  # If it fails, the function returns +nil+.
  #
  # ==== Parameters:
  #
  # +store+::	stream from which to read the file data [FXStream]
  #
  def fxloadTIF(store); end

  #
  # Save a TIFF image to a stream.
  # Returns +true+ on success, +false+ on failure.
  #
  # ==== Parameters:
  #
  # +store+::	stream to which to write the image data [FXStream]
  # +data+::	the image pixel data [String]
  # +transp+::	transparency color [FXColor]
  # +width+::	width [Integer]
  # +height+::	height [Integer]
  # +codec+::	codec setting [Integer]
  #
  def fxsaveTIF(store, data, transp, width, height, codec); end
end

