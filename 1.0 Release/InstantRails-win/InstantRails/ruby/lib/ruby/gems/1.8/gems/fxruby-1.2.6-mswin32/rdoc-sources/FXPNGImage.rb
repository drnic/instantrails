module Fox
  #
  # Portable Network Graphics (PNG) Image
  #
  class FXPNGImage < FXImage
    #
    # Return an initialized FXPNGImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in PNG file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: thePNGImage
    end
  end
end

