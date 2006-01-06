module Fox
  #
  # JPEG Image class
  #
  class FXJPGImage < FXImage
  
    # Image quality
    attr_accessor :quality

    #
    # Return an initialized FXJPGImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in JPEG file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: theJPGImage
    end
  end
end

