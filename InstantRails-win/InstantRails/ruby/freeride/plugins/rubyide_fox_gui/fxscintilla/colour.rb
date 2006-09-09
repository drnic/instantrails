# FreeRIDE Ruby Integrated Development Environment
#
# $Id: colour.rb,v 1.1 2004/09/13 21:28:46 ljulliar Exp $
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

module Scintilla

  class Colour
    def initialize(str)
      @colour = str[1,2].hex + (str[3,2].hex << 8) + (str[5,2].hex << 16)
    end

    def to_i
      @colour
    end

    def red
      @colour & 0xff
    end

    def green
      (@colour >> 8) & 0xff
    end

    def blue
      (@colour >> 16) & 0xff
    end

    def to_hex(value)
      return "0123456789ABCDEF"[(value>>4)&15,1]+"0123456789ABCDEF"[value&15,1]
    end

    def to_s
      "##{to_hex(red)}#{to_hex(green)}#{to_hex(blue)}"
    end

    def to_foxrgba
      (0xff << 24) + (blue << 16) + (green << 8) + red
    end

    BLACK = Colour.new("#000000")
    WHITE = Colour.new("#FFFFFF")
    GRAY = Colour.new("#808080")
    RED = Colour.new("#FF0000")
    GREEN = Colour.new("#00FF00")
    DARK_GRAY = Colour.new("#404040")
  end

end
