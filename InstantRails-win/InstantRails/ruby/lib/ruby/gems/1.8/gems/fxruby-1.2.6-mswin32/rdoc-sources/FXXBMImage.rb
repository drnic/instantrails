module Fox
  #
  # X Bitmap (XBM) image
  #
  class FXXBMImage < FXImage
    #
    # Return an initialized FXXBMImage instance.
    #
    # ==== Parameters:
    #
    # +a+::		an application instance [FXApp]
    # +pixels+::	a memory buffer formatted in XBM file format [String]
    # +mask+::		a memory buffer formatted in XBM file format [String]
    # +opts+::		options [Integer]
    # +w+::		width [Integer]
    # +h+::		height [Integer]
    #
    def initialize(a, pixels=nil, mask=nil, opts=0, w=1, h=1) # :yields: theXBMImage
    end
  end
end

