# FreeRIDE Ruby Integrated Development Environment
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

module Scintilla
  module RubyProperties

    def RubyProperties.extend_object(o)
      super
      o.__apply_properties
    end

    def __apply_properties
      @language="ruby"

      @keywords_1="__LINE__ __FILE__ BEGIN END alias and begin break case class def defined? do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield"

      @statement_indent=5
      @statement_end=10
      @statement_lookback=1
      @block_start=10
      @block_end=10

      @comment_block="#~"
      @tab_timmy_whinge_level=1


      # ruby styles
      # White space
      @style_0=Style.new("fore:#000000")
      # Comment
      @style_1=Style.new("fore:#007F00")+@font_comment
      # Number
      @style_2=Style.new("fore:#007F7F")
      # String
      @style_3=Style.new("fore:#7F007F")+@font_monospace
      # Single quoted string
      @style_4=Style.new("fore:#7F007F")+@font_monospace
      # Keyword
      @style_5=Style.new("fore:#00007F,bold")
      # Triple quotes
      # @style_6=Style.new("fore:#7F0000")
      # Triple double quotes
      @style_7=Style.new("fore:#7F0000")
      # Class name definition
      @style_8=Style.new("fore:#0000FF,bold")
      # Function or method name definition
      @style_9=Style.new("fore:#007F7F,bold")
      # Operators
      @style_10=Style.new("bold")
      # Identifiers
      @style_11=Style.new("fore:#7F7F7F")
      # Comment-blocks
      @style_12=Style.new("fore:#7F7F7F")
      # End of line where string is not closed
      @style_13=Style.new("fore:#000000,back:#E0C0E0,eolfilled")+@font_monospace
      # Matched Operators
      @style_34=Style.new("fore:#0000FF,bold")
      @style_35=Style.new("fore:#FF0000,bold")
      # Braces are only matched in operator style
      @braces_style=10
    end
  end
end
