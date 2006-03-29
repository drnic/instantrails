module Fox
  #
  # Font selection dialog
  #
  class FXFontDialog < FXDialogBox

    # Current font selection [FXFontDesc]
    attr_accessor :fontSelection

    # Return an initialized FXFontDialog instance.
    def initialize(owner, name, opts=0, x=0, y=0, w=600, h=380); end
  end
end

