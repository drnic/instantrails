# FreeRIDE Ruby Integrated Development Environment
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

module Scintilla
  module GlobalProperties

    def GlobalProperties.extend_object(o)
      super
      o.__apply_properties
    end

    def __apply_properties
      # Global initialisation file for SciTE
      # For Linux, place in $prefix/share/scite
      # For Windows, place in same directory as SciTE.EXE (or Sc1.EXE)

      # Globals

      #@magnification=-1
      #@output_magnification=-1

      # Sizes and visibility in edit pane
      # Set line_numbers to 30 if you want to see them or 0 if not
      @line_numbers=30
      @margin_width=16
      @fold_margin_width=16
      #@blank_margin_left=4
      #@blank_margin_right=4
      @buffered_draw=true
      @use_palette=false

      # Element styles
      #@view_eol=1
      @caret_period=500
      @view_whitespace=false
      @view_indentation_whitespace=false
      @view_indentation_guides=true
      @highlight_indentation_guides=true
      #@caret_fore=Colour.new("#FF0000")
      #@caret_width=2
      #@caret_line_back=Colour.new("#FFFED8")
      #@calltip_back=Colour.new("#FFF0FE")
      @edge_column=200
      @edge_mode=0
      @edge_colour=Colour.new("#C0DCC0")
      @braces_check=1
      @braces_sloppy=1
      #@selection_fore=Colour.new("#006000")
      #@selection_back=Colour.new("#E0E0E8")
      # DADADA used as background because it yields standard silver C0C0C0
      # on low colour displays and a reasonable light grey on higher bit depths
      @selection_back=Colour.new("#DADADA")
      #@error_marker_fore=Colour.new("#0000A0")
      #@error_marker_back=Colour.new("#DADAFF")
      #@bookmark_fore=Colour.new("#808000")
      #@bookmark_back=Colour.new("#FFFFA0")

      # Indentation
      @tabsize=2
      @indent_size=2
      @use_tabs=false
      @indent_automatic=true
      @indent_opening=true
      @indent_closing=true
      @tab_indents=true
      @backspace_unindents=true

      # Folding
      # enable folding, and show lines below when collapsed.
      @fold=1
      @fold_compact=1
      @fold_flags=16
      @fold_symbols=1
      #@fold_on_open=1

      # Behaviour
      # Windows is CRLF, all others are assumed Unix. Mac is CR I guess
      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
        @eol_mode = "CRLF"
      else
        @eol_mode="LF"
      end
      #@eol_auto=1
      @clear_before_execute=0
      #@vc_home_key=1
      #@autocompleteword_automatic=1
      #@autocomplete_choose_single=1
      #@caret_policy_strict=1
      #@caret_policy_slop=1
      #@caret_policy_xeven=1
      #@caret_policy_xjumps=1
      #@caret_policy_lines=5
      #@visible_policy_strict=1
      #@visible_policy_slop=1
      #@visible_policy_lines=4

      # Internationalisation
      # Japanese input code page 932 and ShiftJIS character set 128
      #@code_page=932
      #@character_set=128
      # Unicode
      #@code_page=65001
      @code_page=0
      #@character_set=204

      # Export
      #@export_keep_ext=1
      @export_html_wysiwyg=1
      #@export_html_tabs=1
      #@export_html_folding=1
      @export_html_styleused=1
      #@export_html_title_fullpath=1
      #@export_rtf_tabs=1
      #@export_rtf_font_face="Arial"
      #@export_rtf_font_size=9
      #@export_rtf_tabsize=8

      # Define values for use in the imported properties files
      @chars_alpha="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
      @chars_numeric="0123456789"
      @chars_accented="äöåúüˇ¿‡¡·¬‚√„ƒ‰≈Â∆Ê«Á»Ë…È ÍÀÎÃÏÕÌŒÓœÔ–—Ò“Ú”Û‘Ù’ı÷ÿ¯Ÿ˘⁄˙€˚‹¸›˝ﬁ˛ﬂˆ"
      @word_characters = @chars_alpha + @chars_numeric + "_?"

      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
        @font_base=Style.new("font:courier,size:10")
        @font_small=Style.new("font:courier,size:8")
        @font_comment=Style.new("font:courier,size:9")
        @font_code_comment_box=@font_comment
        @font_code_comment_line=@font_comment
        @font_code_comment_doc=@font_comment
        @font_text=Style.new("font:courier,size:11")
        @font_text_comment=Style.new("font:courier,size:8")
        @font_embedded_base=Style.new("font:courier,size:9")
        @font_embedded_comment=Style.new("font:courier,size:8")
        @font_monospace=Style.new("font:courier,size:10")
        @font_vbs=Style.new("font:courier,size:10")
      else
        # make font a bit bigger on Linux
        @font_base=Style.new("font:courier,size:12")
        @font_small=Style.new("font:courier,size:10")
        @font_comment=Style.new("font:courier,size:11")
        @font_code_comment_box=@font_comment
        @font_code_comment_line=@font_comment
        @font_code_comment_doc=@font_comment
        @font_text=Style.new("font:courier,size:12")
        @font_text_comment=Style.new("font:courier,size:10")
        @font_embedded_base=Style.new("font:courier,size:11")
        @font_embedded_comment=Style.new("font:courier,size:10")
        @font_monospace=Style.new("font:courier,size:12")
        @font_vbs=Style.new("font:courier,size:12")
      end

      # Give symbolic names to the set of colours used in the standard styles.
      @colour_code_comment_box=Style.new("fore:#007F00")
      @colour_code_comment_line=Style.new("fore:#007F00")
      @colour_code_comment_doc=Style.new("fore:#3F703F")
      @colour_text_comment=Style.new("fore:#0000FF,back:#D0F0D0")
      @colour_other_comment=Style.new("fore:#007F00")
      @colour_embedded_comment=Style.new("back:#E0EEFF")
      @colour_embedded_js=Style.new("back:#F0F0FF")
      @colour_notused=Style.new("back:#FF0000")

      @colour_number=Style.new("fore:#007F7F")
      @colour_keyword=Style.new("fore:#00007F")
      @colour_string=Style.new("fore:#7F007F")
      @colour_char=Style.new("fore:#7F007F")
      @colour_operator=Style.new("fore:#000000")
      @colour_preproc=Style.new("fore:#7F7F00")
      @colour_error=Style.new("fore:#FFFF00,back:#FF0000")

      # Global default styles for all languages
      # Default
      @style_32=@font_base
      # Line number
      @style_33=Style.new("back:#E8E8F8,fore:#7070C0")+@font_base
      # Brace highlight
      @style_34=Style.new("fore:#0000FF,bold")
      # Brace incomplete highlight
      @style_35=Style.new("fore:#FF0000,bold")
      # Control characters
      @style_36=Style.new
      # Indentation guides
      @style_37=Style.new("fore:#C0C0C0,back:#FFFFFF")
    end
  end
end
