module Fox
  #
  # Portable Pixmap (PPM) Image
  #
  class FXPPMImage < FXImage
    #
    # Return an initialized FXPPMImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in PPM file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: thePPMImage
    end
  end
end

