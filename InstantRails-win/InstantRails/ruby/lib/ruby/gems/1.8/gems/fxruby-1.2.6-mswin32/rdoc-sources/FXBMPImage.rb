module Fox
  #
  # Microsoft Bitmap image.
  #
  class FXBMPImage < FXImage
    #
    # Return an initialized FXBMPImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in BMP file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1)	# :yields: theBMPImage
    end
  end
end
