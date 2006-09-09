# FreeRIDE Ruby Integrated Development Environment
#
# Author: Rich Kilmer
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

require "rubyide_fox_gui/fxscintilla/scintilla_wrapper"
require "rubyide_fox_gui/fxscintilla/global_properties"
require "rubyide_fox_gui/fxscintilla/ruby_properties"
require "rubyide_fox_gui/fxscintilla/ruby_autoindent"
require "rubyide_fox_gui/fxscintilla/ruby_colourize"
require "rubyide_fox_gui/fxscintilla/colour"
require "rubyide_fox_gui/fxscintilla/style"
require 'rbconfig'

module Scintilla

  # define our own marker numbers
  MARKER_DBG_LINE     = 0
  MARKER_BRKPT        = 1
  MARKER_ACTIVE_BRKPT = 2  
  MARKER_ERROR_LINE   = 3
  
  MARKER_FOLD_OPEN    = 4
  MARKER_FOLD_CLOSED  = 5

  def _set_one_style(snum, style)
    set_style_set_italic(snum, style.italic?) if style.specified & Style::ITALIC != 0
    set_style_set_bold(snum, style.bold?) if style.specified & Style::BOLD != 0
    set_style_set_eol_filled(snum, style.eolfilled?) if style.specified & Style::EOLFILLED != 0
    set_style_set_underline(snum, style.underline?) if style.specified & Style::UNDERLINE != 0
    set_style_set_font(snum, style.font) if style.specified & Style::FONT != 0
    set_style_set_size(snum, style.size) if style.specified & Style::SIZE != 0
    set_style_set_fore(snum, style.fore) if style.specified & Style::FORE != 0
    set_style_set_back(snum, style.back) if style.specified & Style::BACK != 0
    set_style_set_case(snum, style.caseForce) if style.specified & Style::CASE_FORCE != 0
  end

  def _set_styles
    @properties.each("style.") do |key, style|
      snum = key[6..-1].to_i
      _set_one_style(snum, style) unless snum == STYLE_DEFAULT
    end
  end

  def _setup
    set_lexer_language(@properties.language)
    language = get_lexer
    if ((language==SCLEX_HTML) || (language==SCLEX_XML))
      style_bits = 7
    else
      style_bits = 4
    end
    set_key_words(0, @properties.keywords_1) if @properties.keywords_1
    set_key_words(1, @properties.keywords_2) if @properties.keywords_2
    set_key_words(2, @properties.keywords_3) if @properties.keywords_3
    set_key_words(3, @properties.keywords_4) if @properties.keywords_4
    set_key_words(4, @properties.keywords_5) if @properties.keywords_5
    set_key_words(5, @properties.keywords_6) if @properties.keywords_6

    _forward_property("fold")
    _forward_property("fold.compact")
    _forward_property("fold.comment")
    _forward_property("fold.comment.python")
    _forward_property("fold.quotes.python")
    _forward_property("fold.html")
    _forward_property("styling.within.preprocessor")
    _forward_property("tab.timmy.whinge.level")
    _forward_property("asp.default.language")

    # eol.mode is normally setup in global properties based
    # on the running platform
    case @properties["eol.mode"]
    when "LF"
      set_eol_mode(SC_EOL_LF)
    when "CR"
      set_eol_mode(SC_EOL_CR)
    when "CRLF"
      set_eol_mode(SC_EOL_CRLF)
    else
      # Assume all others are Unix
      set_eol_mode(SC_EOL_LF)
    end

    set_code_page @properties["code.page", 0]
    set_caret_fore @properties["caret.fore", Colour::BLACK]
    set_mouse_dwell_time @properties["dwell.period", SC_TIME_FOREVER]
    set_caret_width @properties["caret.width", 1]

    if @properties["caret.line.back"]
      set_caret_line_visible true
      set_caret_line_back @properties["caret.line.back"]
    else
      set_caret_line_visible false
    end

    set_call_tip_set_back @properties["calltip.back", Colour::WHITE]
    set_caret_period @properties["caret.period"] if @properties["caret.period"]

    cStrict = @properties["caret.policy.strict",0] ? CARET_STRICT : 0
    cSlop = @properties["caret.policy.slop", 0] ? CARET_SLOP : 0
    cLines = @properties["caret.policy.lines", 0]
    cXEven = @properties["caret.policy.xeven",1] ? CARET_XEVEN : 0
    cXJumps= @properties["caret.policy.xjumps",0] ? CARET_XJUMPS : 0
    set_x_caret_policy(cStrict | cSlop | cXEven | cXJumps, cLines)
    set_y_caret_policy(cStrict | cSlop | cXEven | cXJumps, cLines)

    vStrict = @properties["visible.policy.strict"] ? VISIBLE_STRICT : 0
    vSlop = @properties["visible.policy.slop", 1] ? VISIBLE_SLOP : 0
    vLines = @properties["visible.policy.lines",0]
    set_visible_policy(vStrict | vSlop,  vLines)

    set_edge_column @properties["edge.column", 0]
    set_edge_mode @properties["edge.mode", EDGE_NONE]
    set_edge_colour @properties["edge.color", Colour::BLACK]

    if @properties["selection.fore"]
      set_sel_fore(1, @properties["selection.fore"])
    else
      set_sel_fore(0, 0)
    end
    if @properties["selection.back"]
      set_sel_back(1, @properties["selection.back"])
    else
      if @properties["selection.fore"]
        set_sel_back(0, 0)
      else
        set_sel_back(1, Color::BLACK) #must show selection somehow
      end
    end

    #[skipped calltip stuff]

    set_auto_c_set_ignore_case @properties["autocomplete.ignorecase", false]
    set_auto_c_set_choose_single @properties["autocomplete.choose.single", false]
    set_auto_c_set_cancel_at_start false

    style_reset_default
    _set_one_style(STYLE_DEFAULT, @properties["style.#{STYLE_DEFAULT}"])
    set_style_clear_all
    _set_styles

    # begin ReadPropertiesIntial
    if @properties["view.indentation.whitespace", true] && @properties["view.whitespace", false]
      set_view_ws SCWS_VISIBLEALWAYS
    elsif @properties["view.whitespace", false]
      set_view_ws SCWS_VISIBLEAFTERINDENT
    else
      set_view_ws SCWS_INVISIBLE
    end
    set_indentation_guides @properties["view.indentation.guides", false]
    set_view_eol @properties["view.eol", false]
    set_zoom @properties["magnification", 0]
    # end ReadPropertiesInitial

    set_use_palette @properties["use.palette", false]
    set_print_magnification @properties["print.magnification", 0]
    set_print_colour_mode @properties["print.colour.mode", 0]
    set_margin_left @properties["blank.margin.left", 1]
    set_margin_right @properties["blank.margin.right", 1]
    set_margin_width_n(0, (@properties["line.numbers"].nil? ? 40 : @properties["line.numbers"]) )
    set_margin_width_n(1, (@properties["margin.width"].nil? ? 20 : @properties["margin.width"]) )
    set_margin_sensitive_n(1, true)
    set_margin_width_n(2, (@properties["fold.margin.width", 14]==0 ? 14 : @properties["fold.margin.width", 14]))
    set_margin_sensitive_n(2, true)

    set_buffered_draw @properties["buffered.draw", true]

    if @properties["word.characters"]
      set_word_chars @properties["word.characters"]
    else
      set_word_chars 0
    end
    
    set_mod_event_mask SC_MOD_CHANGEFOLD

    set_use_tabs @properties["use.tabs", true]
    set_tab_indents @properties["tab.indents", true]
    
    set_back_space_un_indents @properties["backspace.unindents", true]
    set_tab_width @properties["tabsize", 2]
    set_indent @properties["indent.size"] if @properties["indent.size", 0] > 0

    set_h_scroll_bar @properties["horizontal.scrollbar", true]

    set_fold_flags @properties["fold.flags", 0]
    
=begin
    case @properties["fold.symbols", 0]
    when 0 #arrow pointing right for contracted folders, arrow pointing down for expanded
      _define_marker(SC_MARKNUM_FOLDEROPEN, SC_MARK_ARROW, Colour::BLACK, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDER, SC_MARK_ARROW, Colour::BLACK, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDERSUB, SC_MARK_EMPTY, Colour::BLACK, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDERTAIL, SC_MARK_EMPTY, Colour::BLACK, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDEREND, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
    when 1 #plus for contracted, minus for expanded
      _define_marker(SC_MARKNUM_FOLDEROPEN, SC_MARK_MINUS, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDER, SC_MARK_PLUS, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDERSUB, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDERTAIL, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDEREND, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
      _define_marker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_EMPTY, Colour::WHITE, Colour::BLACK)
    when 2 # like a flattened tree control using circular headers and curved joints
      _define_marker(SC_MARKNUM_FOLDEROPEN, SC_MARK_CIRCLEMINUS, Colour::BLACK, Colour::DARK_GRAY)
      _define_marker(SC_MARKNUM_FOLDER, SC_MARK_CIRCLEPLUS, Colour::BLACK, Colour::DARK_GRAY)
      _define_marker(SC_MARKNUM_FOLDERSUB, SC_MARK_VLINE, Colour::BLACK, Colour::DARK_GRAY)
      _define_marker(SC_MARKNUM_FOLDERTAIL, SC_MARK_LCORNERCURVE, Colour::BLACK, Colour::DARK_GRAY)
      _define_marker(SC_MARKNUM_FOLDEREND, SC_MARK_CIRCLEPLUSCONNECTED, Colour::WHITE, Colour::DARK_GRAY)
      _define_marker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_CIRCLEMINUSCONNECTED, Colour::WHITE, Colour::DARK_GRAY)
      _define_marker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_TCORNERCURVE, Colour::WHITE, Colour::DARK_GRAY)
    when 3 # like a flattened tree control using square headers
      _define_marker(SC_MARKNUM_FOLDEROPEN, SC_MARK_BOXMINUS, Colour::BLACK, Colour::GRAY)
      _define_marker(SC_MARKNUM_FOLDER, SC_MARK_BOXPLUS, Colour::BLACK, Colour::GRAY)
      _define_marker(SC_MARKNUM_FOLDERSUB, SC_MARK_VLINE, Colour::BLACK, Colour::GRAY)
      _define_marker(SC_MARKNUM_FOLDERTAIL, SC_MARK_LCORNER, Colour::BLACK, Colour::GRAY)
      _define_marker(SC_MARKNUM_FOLDEREND, SC_MARK_BOXPLUSCONNECTED, Colour::WHITE, Colour::GRAY)
      _define_marker(SC_MARKNUM_FOLDEROPENMID, SC_MARK_BOXMINUSCONNECTED, Colour::WHITE, Colour::GRAY)
      _define_marker(SC_MARKNUM_FOLDERMIDTAIL, SC_MARK_TCORNER, Colour::WHITE, Colour::GRAY)
    end

    #set_margin_type_n(2, SC_MARGIN_SYMBOL)
    set_margin_mask_n(2,  (get_margin_mask_n(2) | \
                          (1<<SC_MARKNUM_FOLDER) | \
                          (1<<SC_MARKNUM_FOLDEROPEN) | \
                          (1<<SC_MARKNUM_FOLDERSUB) | \
                          (1<<SC_MARKNUM_FOLDERTAIL) | \
                          (1<<SC_MARKNUM_FOLDERMIDTAIL) | \
                          (1<<SC_MARKNUM_FOLDEROPENMID) | \
                          (1<<SC_MARKNUM_FOLDEREND) )
                      )
=end

    # Caution! fold markers background color must be same color as 
    # the editor background otherwise when fold margin is hidden, text lines
    # with fold markers have their background changed to the color of the
    # marker. It's ugly.
    _define_marker(MARKER_FOLD_OPEN, SC_MARK_MINUS, Colour::BLACK, Colour::WHITE)
    _define_marker(MARKER_FOLD_CLOSED, SC_MARK_PLUS, Colour::BLACK, Colour::WHITE)
    set_margin_mask_n(2,  (1<<MARKER_FOLD_OPEN) | (1<<MARKER_FOLD_CLOSED) )

    #define additional markers

    # marker #0 is to highlight the current line in the debugger
    _define_marker(MARKER_DBG_LINE,SC_MARK_BACKGROUND,Colour::WHITE, Colour.new("#FFFF00"))
    
    #marker #1 is a red dot showing breakpoints in the debugger
    _define_marker(MARKER_BRKPT,SC_MARK_CIRCLE,Colour::RED, Colour::RED)
    # marker #2 is a green dotr with a red countour showing the active 
    # breakpoint in the debugger
    _define_marker(MARKER_ACTIVE_BRKPT,SC_MARK_CIRCLE,Colour::RED, Colour::GREEN)
    # marker #3 is to highlight the current line in the debugger
    _define_marker(MARKER_ERROR_LINE,SC_MARK_ARROW,Colour::BLACK, Colour::RED)
    
    set_margin_mask_n(1, (1<<MARKER_BRKPT) | (1<<MARKER_ACTIVE_BRKPT) | (1<< MARKER_ERROR_LINE))

    #do not perform the SciTE_Bookmark stuff

  end

  def _forward_property(property)
    value = @properties[property]
    value = value.nil? ? "" : value.to_s
    set_property(property, value)
  end

  def _define_marker(marker, type, fore, back)
    marker_define(marker, type)
    marker_set_fore(marker, fore)
    marker_set_back(marker, back)
  end

  class Properties
    def method_missing(property, *args)
      return eval("@#{property}")
    end

    def [](property, default=nil)
      property.gsub!(/\./, '_')
      result = eval("@#{property}")
      return result.nil? ? default : result
    end

    def []=(property, value)
      property.gsub!(/\./, '_')
      result = eval("@#{property} = #{value}")
      return result
    end

    def each(pattern=nil)
      pattern.gsub!(/\./, '_') if pattern
      instance_variables.each do |var|
        yield var, eval(var) if (pattern.nil? || var.include?(pattern))
      end
    end
  end

end # Module Scintilla

class ScintillaModel
  attr_reader :properties, :_view, :_controller
  include Scintilla
  def initialize(controller, view)
    @_controller = controller
    @_view = view
    @properties = Scintilla::Properties.new
    @properties.extend Scintilla::GlobalProperties
    @properties.extend Scintilla::RubyProperties
  end

  def send_message(type, wparam, lparam)
    @_view.sendMessage(type, wparam, lparam)
  end
end

class ScintillaController

  attr_reader :model, :view

  include Scintilla
  include AutoIndent
  include Colourize

  def initialize(view)
    @view = view
    @model = ScintillaModel.new(self, view)
    @model.undo_collection = true
    @auto_indent = @model.properties["indent.automatic"]
    @dbg_handle = nil
    @dbg_prev_line = nil
    @epane_renderer = view.userData # the edit pane renderer object 
    @indent_size = @model.properties["indent.size"]
  end

  def setup
    @model._setup
  end

  def open(fileName)
    @currentFile = fileName
    @buffer = nil
    begin
      File.open(@currentFile, "rb") {|file| @buffer=file.read}
    rescue
      raise # leave it to the caller to handle the exception
    else
      @model.set_text(@buffer)
      @model.empty_undo_buffer
      self.modified = false
    end
  end

  def save(file_name=nil)
    @current_file = file_name if file_name
    return unless @current_file
    begin
      File.open(@current_file, "wb")  do |file|
        file.write(self.text)
      end
    rescue
      raise # leave it to the caller to handle the exception
    else
      @model.set_save_point()
      self.modified = false
    end
  end
  
  def text
    # it looks like get_text is returning a buffer terminated
    # with a null byte (a la C). It must be removed.
    @model.get_text(@model.text_length+1)[0..-2]
  end
  alias :get_text :text

  def text=(text)
    @model.set_text(text)
  end
  alias :set_text :text=

  def text_length
    # it looks like get_text is returning a buffer terminated
    # with a null byte (a la C). It must be removed.
    @model.text_length+1
  end

  def eol_visible=(view)
    @model.view_eol = view
  end
  
  def is_eol_visible?
    @model.get_view_eol
  end

  def caret_period=(msec)
    @model.set_caret_period(msec)
  end

  def caret_period
    @model.get_caret_period
  end

  def whitespace_visible=(view)
    if view
      @model.view_ws = Scintilla::SCWS_VISIBLEALWAYS
    else
      @model.view_ws = Scintilla::SCWS_INVISIBLE
    end
  end
  
  def is_whitespace_visible?
    @model.view_ws != SCWS_INVISIBLE
  end

  def linenumbers_visible=(status)
    if status
      @model.set_margin_width_n(0, (@model.properties["line.numbers", 40] ==0 ? 40 : @model.properties["line.numbers", 40]) )
    else
      @model.set_margin_width_n(0, 0 )
    end
  end
  
  def are_linenumbers_visible?
    return @model.get_margin_width_n(0) > 0 ? true : false
  end
  
  def indentation_guides_visible=(status)
    @model.set_indentation_guides(status)
  end

  def are_indentation_guides_visible?
    @model.get_indentation_guides
  end

  def wrap_mode=(status)
    @model.wrap_mode = (status ? Scintilla::SC_WRAP_WORD : Scintilla::SC_WRAP_NONE)
  end

  def wrap_mode
    @model.get_wrap_mode == Scintilla::SC_WRAP_WORD ? true : false
  end

  def clear_all
    @model.clear_all
  end

  def undo
    @model.undo
  end

  def redo
    @model.redo
  end

  def cut
    @model.cut
  end

  def copy
    @model.copy
  end

  def paste
    @model.paste
  end

  def breakpoint_margin=(status)
    if status
      @model.set_margin_width_n(1, (@model.properties["line.numbers", 20] ==0 ? 20 : @model.properties["line.numbers", 20]) )
    else
      @model.set_margin_width_n(1, 0 )
    end
  end

  def modified?
    @modified
  end

  def modified=(flag)
    @modified = flag
    @epane_renderer.modified = flag if !@epane_renderer.nil?
  end

  def read_only=(status)
    @model.set_read_only(status)
  end
  alias :set_read_only :read_only=

  def read_only?
    @model.get_read_only
  end
  alias :get_read_only :read_only?

  def h_scroll_bar=(status)
    @model.set_h_scroll_bar(status)
  end
  alias :set_h_scroll_bar :h_scroll_bar=

  def h_scroll_bar?
    @model.get_h_scroll_bar
  end
  alias :get_h_scroll_bar :h_scroll_bar?

  ##
  # Highlight a given line in the text (error line). If line
  # number is nil then hide the marker
  #
  def show_errorline(line)
    if line.nil?
      @model.marker_delete_handle(@err_handle) unless @err_handle == nil
      return
    end
    l = line.to_i-1

    # delete previous highlighted line and show the new one
    @model.marker_delete_handle(@err_handle) unless @err_handle == nil
    @err_handle = @model.marker_add(l, Scintilla::MARKER_ERROR_LINE)

    # scroll up/down if line not visible on screen
    @model.goto_line(l)
  end

  ##
  # Highlight a given line in the text (current debugger line). If line
  # number is nil then hide the marker
  #
  def show_debugline(line)
    if line.nil?
      @model.marker_delete_handle(@dbg_handle) unless @dbg_handle == nil
      return
    end

    l = line.to_i-1
    if (@dbg_prev_line != nil)
      # reset the breakpoint marker to full red if there was one
      # on the previous line
      if ( @model.marker_get(@dbg_prev_line) & (1<<Scintilla::MARKER_ACTIVE_BRKPT) != 0 )
        @model.marker_delete(@dbg_prev_line,Scintilla::MARKER_ACTIVE_BRKPT)
        @model.marker_add(@dbg_prev_line,Scintilla::MARKER_BRKPT)
      end
    end
    @dbg_prev_line = l

    # delete previous highlighted line and show the new one
    @model.marker_delete_handle(@dbg_handle) unless @dbg_handle == nil
    @dbg_handle = @model.marker_add(l, Scintilla::MARKER_DBG_LINE)

    # now change the breakpoint marker to green to show we are on it (if any)
    if (@model.marker_get(l) & (1<<Scintilla::MARKER_BRKPT) != 0)
      @model.marker_delete(l,Scintilla::MARKER_BRKPT)
      @model.marker_add(l,Scintilla::MARKER_ACTIVE_BRKPT)
    end

    # scroll up/down if line not visible on screen
    @model.goto_line(l)
  end

  ##
  # line the cursor is on (line numbering starts at zero)
  #
  def cursor_line
    @model.line_from_position(@model.get_current_pos)
  end
  
  ##
  # Go to the specific line
  #
  def cursor_line=(line)
    @model.goto_line(line)
  end

  ##
  # Get code folding status: on (true) or off (false)
  #
  def code_folding
    @model.get_margin_width_n(2) > 0
  end
  
  ##
  # Set code folding status: on (true) or off (false)
  #
  def code_folding=(status)

    if status
      return if @model.get_margin_width_n(2) > 0

      # restore initial fold margin length
      @model.set_margin_width_n(2, (@model.properties["fold.margin.width", 16] ==0 ? 16 : @model.properties["fold.margin.width", 16]) )

      # update all lines with fold markers (not needed if markers are
      # not deleted)
      #0.upto(@model.get_line_count - 1) do |line|
      #  update_fold(line)
      #end

    else
      return if @model.get_margin_width_n(2) == 0

      # scan all lines to make sure all blocks are expanded and
      # delete all markers to prevent black lines to appear when
      # margin width is reduced to zero. (not needed if marker
      # background same color as editor background)
      0.upto(@model.get_line_count - 1) do |line|
	fold_level = @model.get_fold_level(line)
	marker = @model.marker_get(line)
	if (fold_level & Scintilla::SC_FOLDLEVELHEADERFLAG)==Scintilla::SC_FOLDLEVELHEADERFLAG
	  if @model.fold_expanded?(line)
	    #@model.marker_delete(line, Scintilla::MARKER_FOLD_OPEN) unless (marker & (1<<Scintilla::MARKER_FOLD_OPEN))==0
	  else
	    @model.toggle_fold(line)
	    update_fold(line)
	    #@model.marker_delete(line, Scintilla::MARKER_FOLD_CLOSED) unless (marker & (1<<Scintilla::MARKER_FOLD_CLOSED))==0
	  end
	end
	@model.set_margin_width_n(2, 0)
      end

    end
  end

  ##
  # Set a Scintilla style 
  #
  def set_style(style_name, style)
    style_number = Colourize::STYLE_NUMBER[style_name]
    #print "Style name: #{style_name} (#{style_number}) -> #{style.to_s}\n"
    @model._set_one_style(style_number, style) unless style_number.nil?
  end

  ##
  # reset all scintilla styles to default 
  #
  def set_style_clear_all()
    @model.set_style_clear_all
  end
  
  ##
  # Add/Delete breakpoint on the given line
  # (add if there is none, delete if there is one)
  def toggle_breakpoint(line, notify=true)
    if ( @model.marker_get(line) & (1<<Scintilla::MARKER_BRKPT | 1<<Scintilla::MARKER_ACTIVE_BRKPT) == 0)
      @model.marker_add(line, Scintilla::MARKER_BRKPT)
      @epane_renderer.add_breakpoint(line+1) if notify && @epane_renderer
    else
      @model.marker_delete(line, Scintilla::MARKER_BRKPT)
      @model.marker_delete(line, Scintilla::MARKER_ACTIVE_BRKPT)
      @epane_renderer.delete_breakpoint(line+1) if notify  && @epane_renderer
    end
  end
  
  def update_fold(line, fold_level=nil)
    fold_level = @model.get_fold_level(line) unless fold_level
    marker = @model.marker_get(line)
    if (fold_level & Scintilla::SC_FOLDLEVELHEADERFLAG)==Scintilla::SC_FOLDLEVELHEADERFLAG
      if @model.fold_expanded?(line)
        @model.marker_delete(line, Scintilla::MARKER_FOLD_CLOSED) unless (marker & (1<<Scintilla::MARKER_FOLD_CLOSED))==0
        @model.marker_add(line, Scintilla::MARKER_FOLD_OPEN) if (marker & (1<<Scintilla::MARKER_FOLD_OPEN))==0
      else
        @model.marker_delete(line, Scintilla::MARKER_FOLD_OPEN) unless (marker & (1<<Scintilla::MARKER_FOLD_OPEN))==0
        @model.marker_add(line, Scintilla::MARKER_FOLD_CLOSED) if (marker & (1<<Scintilla::MARKER_FOLD_CLOSED))==0
      end
    else
      @model.marker_delete(line, Scintilla::MARKER_FOLD_CLOSED) unless (marker & (1<<Scintilla::MARKER_FOLD_CLOSED))==0
      @model.marker_delete(line, Scintilla::MARKER_FOLD_OPEN) unless (marker & (1<<Scintilla::MARKER_FOLD_OPEN))==0
    end
  end

  # extract the word under or next to the cursor (caret)
  def word_at_cursor
    ws = @model.word_start_position(@model.get_current_pos,true)
    we = @model.word_end_position(@model.get_current_pos,true)
    tr = TextRange.new(ws,we,we-ws+10) # +1 is enough in theory...
    @model.get_text_range(tr)
    word = tr.lpstrText
    return word,ws,we
  end

  def help_lookup

    word,ws,we = word_at_cursor()

    # also extract what's before and after that word on the line
    line = @model.line_from_position(ws)
    end_pos = @model.get_line_end_position(line)
    begin_pos = end_pos - @model.line_length(line) + 1

    if begin_pos == ws
      text_before = ''
    else
      tr_before = TextRange.new(begin_pos, ws , ws-begin_pos+10)
      @model.get_text_range(tr_before)
      text_before = tr_before.lpstrText
    end

    if ws == end_pos
      text_after = ''
    else
      tr_after = TextRange.new(we+1, end_pos, end_pos-we+10)
      @model.get_text_range(tr_after)
      text_after = tr_after.lpstrText
    end
    #puts "word: #{word}, before: #{text_before}, after: #{text_after}"
    return word,text_before,text_after

  end # of help_lookup

  include Scintilla::ScintillaEvents

  def on_key(ch, modifiers)
    #puts "key: #{ch}, modifiers: #{modifiers}"
    #help_lookup() if ch == 32 && (modifiers & SCMOD_CTRL == SCMOD_CTRL)
  end

  def on_style_needed(position)
    colourize(position)
  end
  
  def on_char_added(ch)
    automatic_indentation(ch) if @auto_indent
    # start an undo action whenever a new line is created
    if (ch == 13)
      @model.end_undo_action
      @model.begin_undo_action
    end
  end
  
  def on_save_point_reached
    self.modified = false
    #used for changing menus
  end
  
  def on_save_point_left
    self.modified = true
    #used for changing menus
  end
  
  def on_margin_click(modifiers, position, margin)
    # shift-click -> place a breakpoint
    line = @model.line_from_position(position)
    if ((modifiers & SCMOD_SHIFT) == SCMOD_SHIFT && margin == 1)
      toggle_breakpoint(line)
    elsif margin==2
      @model.toggle_fold(line)
      update_fold(line)
    end
  end
  
  def on_modified(position, modification_type, text, length, lines_added, line, fold_level_now, fold_level_prev)
    if modification_type==520
      update_fold(line, fold_level_now)
    end
  end

end
