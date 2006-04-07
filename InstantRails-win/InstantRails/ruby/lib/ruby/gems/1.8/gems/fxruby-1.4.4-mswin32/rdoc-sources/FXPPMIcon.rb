module Fox
  #
  # Portable Pixmap (PPM) icon class.
  #
  class FXPPMIcon < FXIcon
    #
    # Return the suggested file extension for this image type ("ppm").
    #
    def FXPPMIcon.fileExt; end

    #
    # Return an initialized FXPPMIcon instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in PPM file format [String]
    # +clr+::	transparency color [FXColor]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, clr=0, opts=0, w=1, h=1) # :yields: thePPMIcon
    end
  end
  
  #
  # Return +true+ if _store_ (an FXStream instance) contains a PPM image.
  #
  def Fox.fxcheckPPM(store); end
end
