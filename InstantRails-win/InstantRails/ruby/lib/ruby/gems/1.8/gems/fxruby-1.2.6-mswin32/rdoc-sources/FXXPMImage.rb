module Fox
  #
  # X Pixmap (XPM) Image
  #
  class FXXPMImage < FXImage
    #
    # Return an initialized FXXPMImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in XPM file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: theXPMImage
    end
  end
end

