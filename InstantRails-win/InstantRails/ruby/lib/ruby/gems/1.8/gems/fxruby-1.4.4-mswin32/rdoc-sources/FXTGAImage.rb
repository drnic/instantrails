module Fox
  #
  # Targa Image
  #
  class FXTGAImage < FXImage
    #
    # Return the suggested file extension for this image type ("tga").
    #
    def FXTGAImage.fileExt; end

    #
    # Return an initialized FXTGAImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in Targa file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: theTGAImage
    end
  end
end

