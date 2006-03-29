module Fox
  #
  # Tagged Image File Format (TIFF) Image
  #
  class FXTIFImage < FXImage
    # Codec setting [Integer]
    attr_accessor :codec
    
    #
    # Return an initialized FXTIFImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in TIF file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: theTIFImage
    end
  end
end

