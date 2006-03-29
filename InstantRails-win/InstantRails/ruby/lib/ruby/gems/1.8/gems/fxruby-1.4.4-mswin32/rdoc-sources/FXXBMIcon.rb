module Fox
  #
  # X Bitmap (XBM) Icon
  #
  class FXXBMIcon < FXIcon
    #
    # Return the suggested file extension for this image type ("xbm").
    #
    def FXXBMIcon.fileExt; end

    #
    # Return an initialized FXXBMIcon instance.
    #
    # ==== Parameters:
    #
    # +a+::		an application instance [FXApp]
    # +pixels+::	a memory buffer formatted in XBM file format [String]
    # +mask+::		a memory buffer formatted in XBM file format [String]
    # +clr+::		transparency color [FXColor]
    # +opts+::		options [Integer]
    # +w+::		width [Integer]
    # +h+::		height [Integer]
    #
    def initialize(a, pixels=nil, mask=nil, clr=0, opts=0, w=1, h=1) # :yields: theXBMIcon
    end
  end
  
  #
  # Return +true+ if _store_ (an FXStream instance) contains an XBM image.
  #
  def Fox.fxcheckXBM(store); end
end
