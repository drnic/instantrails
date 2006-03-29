module Fox
  #
  # Iris RGB Image
  #
  class FXRGBImage < FXImage
    #
    # Return an initialized FXRGBImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in IRIS RGB file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: theRGBImage
    end
  end
end

