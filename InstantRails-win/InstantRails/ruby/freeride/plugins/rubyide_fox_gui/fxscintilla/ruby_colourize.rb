# FreeRIDE Ruby Integrated Development Environment
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

module Colourize
  SCE_RUBY_DEFAULT = 0
  SCE_RUBY_COMMENT = 1
  SCE_RUBY_NUMBER = 2
  SCE_RUBY_STRING = 3
  SCE_RUBY_STRING_SINGLE = 4
  SCE_RUBY_KEYWORD = 5
  SCE_RUBY_TRIPLE_QUOTES = 7
  SCE_RUBY_CLASS_NAME = 8
  SCE_RUBY_METHOD = 9
  SCE_RUBY_OPERATOR = 10
  SCE_RUBY_IDENTIFIER = 11
  SCE_RUBY_COMMENT_BLOCK = 12
  SCE_RUBY_STRING_OPEN = 13

  # Scintilla Style name to style number mapping
  STYLE_NUMBER = {
      "WHITE_SPACE" => 0,
      "COMMENT"   => 1,
      "NUMBER"   => 2,
      "STRING"   => 3,
      "STRING_SINGLE"   => 4,
      "KEYWORD"   => 5,
      "TRIPLE_QUOTES"   => 7,
      "CLASS_NAME"   => 8,
      "METHOD"   => 9,
      "OPERATOR"   => 10,
      "IDENTIFIER"   => 11,
      "COMMENT_BLOCK"   => 12,
      "STRING_OPEN"   => 13,

      "DEFAULT" => 32,
      "LINE_NUMBER" => 33,
      "BRACE_HIGHLIGHT" => 34,
      "BRACE_INCOMPLETE_HIGHLIGHT" => 35,
      "CONTROL_CHARACTERS" => 36,
      "INDENT_GUIDES" => 37   }

  def colourize(start_pos)
=begin
    keywords = @model.properties["keywords.1"]
    current_line = @model.line_from_position(start_pos)
    start_pos = @model.get_line_indent_position(current_line)
    #puts "colourizing #{position}"
    length_doc = @model.length
    init_style = start_pos>0 ? @model.get_style_at(start_pos-1) : SCE_RUBY_DEFAULT
    i = startPos
    while i < length_doc
      ch = @model.get_char_at(i)
      new_style = nil
      current_style = init_style
      case current_style
      when  SCE_RUBY_COMMENT
      when  SCE_RUBY_NUMBER
      when  SCE_RUBY_STRING
      when  SCE_RUBY_STRING_SINGLE
      when  SCE_RUBY_KEYWORD
      when  SCE_RUBY_TRIPLE_QUOTES
      when  SCE_RUBY_CLASS_NAME
      when  SCE_RUBY_METHOD
      when  SCE_RUBY_OPERATOR
   when  SCE_RUBY_IDENTIFIER
      when  SCE_RUBY_COMMENT_BLOCK
      when  SCE_RUBY_STRING_OPEN
      when  SCE_RUBY_DEFAULT

      end
    end
=end
  end
end
