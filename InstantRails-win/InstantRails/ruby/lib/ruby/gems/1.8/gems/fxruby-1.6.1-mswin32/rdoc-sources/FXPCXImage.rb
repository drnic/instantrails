module Fox
  #
  # PCX graphics file
  #
  class FXPCXImage < FXImage
    #
    # Return the suggested file extension for this image type ("pcx").
    #
    def FXPCXImage.fileExt; end
    
    #
    # Return the MIME type for this image type
    #
    def FXPCXImage.mimeType; end

    #
    # Return an initialized FXPCXImage instance.
    #
    # ==== Parameters:
    #
    # +a+::	an application instance [FXApp]
    # +pix+::	a memory buffer formatted in PCX file format [String]
    # +opts+::	options [Integer]
    # +w+::	width [Integer]
    # +h+::	height [Integer]
    #
    def initialize(a, pix=nil, opts=0, w=1, h=1) # :yields: thePCXImage
    end
  end
end

