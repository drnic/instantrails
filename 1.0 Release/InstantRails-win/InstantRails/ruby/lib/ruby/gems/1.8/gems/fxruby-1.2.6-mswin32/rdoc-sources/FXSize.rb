module Fox
  #
  # Size
  #
  class FXSize
    # Width [Integer]
    attr_accessor :w
    
    # Height [Integer]
    attr_accessor :h

    #
    # Return an uninitialized FXSize instance.
    #
    def initialize; end

    #
    # Return an initialized FXSize instance which is a copy
    # of the input size _s_ (an FXSize instance).
    #
    def initialize(s); end

    #
    # Return an initialized FXSize instance, where _ww_ and
    # _hh_ are the initial width and height.
    #
    def initialize(ww, hh); end
  end
end

