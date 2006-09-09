# Purpose: Configure the editor settings and preferences UI
#
# $Id: editpane_configurator.rb,v 1.16 2005/11/03 10:59:01 martinleech Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
# Contributors: 
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2004 Laurent Julliard. All rights reserved.
#
begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end
require 'fox12/colors'
require 'fox12/responder'
require 'rubyide_fox_gui/fxscintilla/style'

module FreeRIDE
  module FoxRenderer

    include Fox

    class EditPaneConfiguratorRenderer
      include Fox
      include Scintilla
      ICON_PATH = "/system/ui/icons/EditPane"

      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
	FONT_BASE = "font:courier,size:10"
	FONT_COMMENT = "font:courier,size:10"
	FONT_MONOSPACE = "font:courier,size:10"
      else
        FONT_BASE = "font:courier,size:12"
	FONT_COMMENT = "font:courier,size:12"
	FONT_MONOSPACE = "font:courier,size:12"
      end

      STYLES = {
	# Global Default Styles 
	"DEFAULT" => Style.new(FONT_BASE,'DEFAULT','Default style'),
	"LINE_NUMBER" => Style.new("back:#E8E8F8,fore:#7070C0","LINE_NUMBER",'Line number'),
	"BRACE_HIGHLIGHT" => Style.new("fore:#0000FF,bold","BRACE_HIGHLIGHT",'Brace highlight'),
	"BRACE_INCOMPLETE_HIGHLIGHT" => Style.new("fore:#FF0000,bold","BRACE_INCOMPLETE_HIGHLIGHT", 'Brace incomplete highlight'),
	"CONTROL_CHARACTERS" => Style.new("","CONTROL_CHARACTERS",'Control characters'),
	"INDENT_GUIDES" => Style.new("fore:#C0C0C0","INDENT_GUIDES",'Indentation guides'),
	# Ruby Language styles
	"WHITE_SPACE" => Style.new("fore:#000000","WHITE_SPACE",'White spaces'),
	"COMMENT"   => Style.new("fore:#007F00",'COMMENT','Comment'),
	"NUMBER"   => Style.new("fore:#007F7F",'NUMBER','Number'),
	"STRING"   => Style.new("fore:#7F007F","STRING", 'Double quoted string'),
	"STRING_SINGLE"   => Style.new("fore:#7F007F", "STRING_SINGLE",'Single quoted string'),
	"KEYWORD"   => Style.new("fore:#00007F,bold",'KEYWORD','Keywords'),
	"TRIPLE_QUOTES"   => Style.new("fore:#7F0000","TRIPLE_QUOTES",'Triple quotes'),
	"CLASS_NAME"   => Style.new("fore:#0000FF,bold","CLASS_NAME",'Class name'),
	"METHOD"   => Style.new("fore:#007F7F,bold","METHOD","Method name"),
	"OPERATOR"   => Style.new("bold","OPERATOR","Operators"),
	"IDENTIFIER"   => Style.new("fore:#7F7F7F","IDENTIFIER","Identifiers"),
	"COMMENT_BLOCK"   => Style.new("fore:#7F7F7F","COMMENT_BLOCK",'Comment block'),
	"STRING_OPEN"   => Style.new("fore:#000000,back:#E0C0E0,eolfilled","STRING_OPEN",'Open string')

      }

      SAMPLE_RUBY_CODE = %q{# A comment line
CONSTANT = "FreeRIDE rocks!"
class SampleClass
  
  def initialize(arg1)
    @a = arg1 + 10
    stg1 = "Double quoted string" + 'Single quoted string'
    stg = "An unfinished string... 
  end

end}#"

     # must be the same values as the odp combo box indexes below
     OPEN_DIR_CURRENT = 0
     OPEN_DIR_LAST_VISITED = 1


      def initialize(plugin)
	@plugin = plugin
	@ep_plugin = @plugin['/plugins/rubyide_fox_gui-editpane'].manager
	main = plugin['/system/ui/fox/FXMainWindow'].data


	# init all default settings for preferences
	init_all_config

  init_styles
	@styles_changed = []

	# create the config pane UI. Parent it to the main window for now
	#
	config_pane = FXVerticalFrame.new(main, FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)

	disp_gb = FXGroupBox.new(config_pane, "Display",
				 LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
	cb_hfm = FXHorizontalFrame.new(disp_gb, FRAME_NONE,0,0,0,0,0,0,0,0)
	@cb = FXCheckButton.new(cb_hfm, "Cursor blinking (ms)", nil, 0,
				ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	@cbms = FXTextField.new(cb_hfm, 4, nil, 0, (LAYOUT_TOP|FRAME_THICK))

	FXLabel.new(cb_hfm, "  Color",nil,JUSTIFY_LEFT|LAYOUT_SIDE_TOP)
	@cfore = FXColorWell.new(cb_hfm, FXColor::Black,
		nil, 0, (LAYOUT_SIDE_TOP|LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y), 0, 0, 50, 30,0,0,0,0)
	@cfore.connect(SEL_COMMAND, method(:onCmdCursorFore))

	FXLabel.new(cb_hfm, "  Width (px)",nil,JUSTIFY_LEFT|LAYOUT_SIDE_TOP)
	@cw = FXSpinner.new(cb_hfm, 2, nil, 0, SPIN_NORMAL|FRAME_THICK|LAYOUT_SIDE_TOP)
	@cw.range = 0..4
	#FXTextField.new(cb_hfm, 4, nil, 0, (LAYOUT_SIDE_TOP|FRAME_THICK))

	@lw = FXCheckButton.new(disp_gb, "Line wrapping", nil, 0,
				ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	@cf = FXCheckButton.new(disp_gb, "Code folding", nil, 0,
				ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	@ln = FXCheckButton.new(disp_gb, "Show line numbers", nil, 0,
				JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	@ig = FXCheckButton.new(disp_gb, "Show indentation guides", nil, 0,
				ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	@eol = FXCheckButton.new(disp_gb, "Show end of line character", nil, 0,
				 ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	@ws = FXCheckButton.new(disp_gb, "Show white spaces", nil, 0,
				ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)

	file_gb = FXGroupBox.new(config_pane, "Files",
				 LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
	odp_hfm = FXHorizontalFrame.new(file_gb, FRAME_NONE,0,0,0,0,0,0,0,0)
	FXLabel.new(odp_hfm, "Directory of Open File dialog box is: ",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)
	@odp = FXComboBox.new(odp_hfm, 14, nil, 0,
      COMBOBOX_INSERT_LAST|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)
	@odp.setNumVisible(2)
	@odp.appendItem("Current File Path")
	@odp.appendItem("Last Visited")
  file_ext_hfrm = FXHorizontalFrame.new(file_gb, FRAME_NONE)
  FXLabel.new(file_ext_hfrm, "File extensions visible in File View:")
  @fel = FXTextField.new(file_ext_hfrm, 25, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X)

	config_pane.create
	config_pane.hide

	# Each and every config pane must define  the following attributes:
	# - the config pane manager must be 'self'
	# - attr_icon is a smal size icon that will show up in the configuration
	#   tree of the configurator dialog box
	# - attr_label is the label that will appear next to the icon (see previous point)
	# - attr_description contains a longer description
	# - attr_frame is the FOX dialog box object to insert in the configuration
	#    dialog box
	#
	# Several configuration pane can be defined by a plugin either at
	# the same level or hierarchically e.g
	# configurator/Debugger
	# configurator/Run
	# configurator/Run/Profiling
	#
	plugin['configurator'].manager = self

	pcfg = plugin["configurator/Editor"]
	pcfg.attr_icon = plugin[ICON_PATH+'/editor'].data
	pcfg.attr_label = 'Editor'
	pcfg.attr_description = 'Editor Settings'
	pcfg.attr_frame = config_pane

	# Colors and Fonts sub-panel
	color_pane = FXVerticalFrame.new(main, FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)

	ef_gb = FXGroupBox.new(color_pane, "Editor Default Font",
			       LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
	ft_hfm = FXHorizontalFrame.new(ef_gb, FRAME_NONE,0,0,0,0,0,0,0,0)
	FXLabel.new(ft_hfm, "Name: ",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)
	@ftn = FXLabel.new(ft_hfm, @styles['DEFAULT'].font,nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y|FRAME_LINE)
	FXLabel.new(ft_hfm, "   Size: ",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)
	@fts = FXLabel.new(ft_hfm, @styles['DEFAULT'].size.to_s,nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y|FRAME_LINE)
	FXLabel.new(ft_hfm, "pt      ",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)
	FXButton.new(ft_hfm," ... \tChoose editor font\tChoose editor font", nil, nil, 0, FRAME_RAISED) do |button|
	  button.connect(SEL_COMMAND, method(:onCmdSelectEditorFont))
	end

	style_vf = FXVerticalFrame.new(color_pane, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE,0,0,0,0,0,0,0,0)
	style_sp  = FXSplitter.new(style_vf, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_VERTICAL)
	style_hf1 = FXHorizontalFrame.new(style_sp, FRAME_NONE,0,0,0,0,0,0,0,0)

	@style_lb = FXList.new(style_hf1, nil, 0,LIST_NORMAL|LAYOUT_FILL_X)
	@style_lb.setNumVisible(8)
	@styles.each { |style|  @style_lb.appendItem(style.description,nil,style.name) }	
	@style_lb.setCurrentItem(0)
	@style_lb.selectItem(0)
	@style_lb.connect(SEL_COMMAND, method(:onCmdShowStyle))


	fs_vf1 = FXVerticalFrame.new(style_hf1, FRAME_NONE,0,0,0,0,0,0,0,0)
	fc_hf1 = FXHorizontalFrame.new(fs_vf1, FRAME_NONE,0,0,0,0,0,0,0,0)
	FXLabel.new(fc_hf1, "Font style:   ",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)

	@bold_cbox = FXCheckButton.new(fc_hf1, "Bold   ", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP) do |button|
	  button.connect(SEL_COMMAND, method(:onCmdToggleBold))
	end

	@italic_cbox = FXCheckButton.new(fc_hf1, "Italic   ", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP) do |button|
	  button.connect(SEL_COMMAND, method(:onCmdToggleItalic))
	end

	@underline_cbox = FXCheckButton.new(fc_hf1, "Underline   ", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP) do |button|
	  button.connect(SEL_COMMAND, method(:onCmdToggleUnderline))
	end

	fw_hf = FXHorizontalFrame.new(fs_vf1, FRAME_NONE,0,0,0,0,0,0,0,0)
	@forewell = FXColorWell.new(fw_hf, FXColor::White,
		nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|
                LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 50, 30)
	@forewell.connect(SEL_COMMAND, method(:onCmdForeWell))
	FXLabel.new(fw_hf, "  Foreground",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)


	bw_hf = FXHorizontalFrame.new(fs_vf1, FRAME_NONE,0,0,0,0,0,0,0,0)
	@backwell = FXColorWell.new(bw_hf, FXColor::White,
		nil, 0, (LAYOUT_CENTER_X|LAYOUT_TOP|LAYOUT_LEFT|
                LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT), 0, 0, 50, 30)
	@backwell.connect(SEL_COMMAND, method(:onCmdBackWell))
	FXLabel.new(bw_hf, "  Background",nil,JUSTIFY_LEFT|LAYOUT_CENTER_Y)

	scintilla = FXScintilla.new(style_sp, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
	@controller = ScintillaController.new(scintilla)
	@controller.setup
	@controller.text = SAMPLE_RUBY_CODE
	@controller.read_only = true
	@controller.h_scroll_bar = false
	@controller.indentation_guides_visible = true
	@controller.linenumbers_visible = true
	@controller.whitespace_visible = true

	#FXFontSelector.new(ft_hfm, nil, 0)

	color_pane.create
	color_pane.hide
	
	pcfg['colors&fonts'].attr_icon = plugin[ICON_PATH+'/fonts'].data
	pcfg['colors&fonts'].attr_label = 'Colors & Fonts'
	pcfg['colors&fonts'].attr_description = 'Settings Editor Colorizing and Fonts'
	pcfg['colors&fonts'].attr_frame = color_pane

	reload_styles

      end # of initialize
	
      def modified?(config_slot)
        case config_slot.name
        when 'Editor'
          return (
            @ep_plugin.properties['cursor_blinking'] != @cb.check or
            @ep_plugin.properties['cursor_blinking_period'] != @cbms.text.to_i or
            @ep_plugin.properties['cursor_fore'] != @cfore.rgba or
            @ep_plugin.properties['cursor_width'] != @cw.value or
            @ep_plugin.properties['line_wraping'] != @lw.check or
            @ep_plugin.properties['code_folding'] != @cf.check or
            @ep_plugin.properties['line_numbers'] != @ln.check or
            @ep_plugin.properties['indent_guides'] != @ig.check or
            @ep_plugin.properties['eol'] != @eol.check or
            @ep_plugin.properties['white_space'] != @ws.check or
            @ep_plugin.properties['open_dir_policy'] != @odp.getCurrentItem or
            @plugin['/plugins/rubyide_tools_fox_file_browser/properties/FileTypes'].data != @fel.text
          )
        when 'colors&fonts'
          return (
            @ep_plugin.properties['fxdefault_fontdesc'] != @fxdefault_fontdesc or
            @styles_changed.size > 0
          )
        end
      end

      ##
      # set_properties is a method called by the configurator plugin
      # whenever the "Apply" button is used to save the new plugin
      # settings
      #
      # config_slot: input parameter passed by the configurator plugin
      # in case there are several configuration pane for the same plugin
      #
      def set_config_properties(config_slot)
	case config_slot.name
	when 'Editor'
	  @ep_plugin.properties.auto_save = false
	  @ep_plugin.properties['cursor_blinking'] = @cb.check
	  @ep_plugin.properties['cursor_blinking_period'] = @cbms.text.to_i
	  @ep_plugin.properties['cursor_fore'] = @cfore.rgba
	  @ep_plugin.properties['cursor_width'] = @cw.value
	  @ep_plugin.properties['line_wraping'] = @lw.check
	  @ep_plugin.properties['code_folding'] = @cf.check
	  @ep_plugin.properties['line_numbers'] = @ln.check
	  @ep_plugin.properties['indent_guides'] = @ig.check
	  @ep_plugin.properties['eol'] = @eol.check
	  @ep_plugin.properties['white_space'] = @ws.check
	  @ep_plugin.properties['open_dir_policy'] = @odp.getCurrentItem
    @ep_plugin.properties.auto_save = true
	  @ep_plugin.properties.save

	  # (un)check the commands in the View Menu that needs to
	  @plugin['/system/ui/commands/App/View/LineNumbers'].manager.checked = @ln.check
	  @plugin['/system/ui/commands/App/View/Whitespace'].manager.checked = @ws.check
	  @plugin['/system/ui/commands/App/View/EndOfLine'].manager.checked = @eol.check
    
    # Removed the call to notify() below as it's causing crashes. View menu seems to refresh anyway
	  #@plugin['/system/ui/components/MenuPane/View_menu'].notify(:refresh)

	  # Apply new configuration to all open edit panes
	  @ep_plugin['/system/ui/components/EditPane'].each_slot do |ep_slot|
	    apply_editor_config(ep_slot)
	  end
    
    @plugin['/plugins/rubyide_tools_fox_file_browser/properties/FileTypes'].data = @fel.text
	when 'colors&fonts'

	  # save new settings in the plugin properties. Disable auto saving
	  # otherwise the loop beloe is way too long. Make one single save
	  # once all properties have been set
	  @ep_plugin.properties['fxdefault_fontdesc'] = @fxdefault_fontdesc
	  @ep_plugin.properties.auto_save = false
	  @styles_changed.each do |style_name|
	    prop_name = 'style_'+style_name.downcase
	    @ep_plugin.properties[prop_name] = @styles[style_name]
	  end
	  @ep_plugin.properties.auto_save = true
	  @ep_plugin.properties.save

	  @ep_plugin['/system/ui/components/EditPane'].each_slot do |ep_slot|
	    apply_colors_fonts(ep_slot)
	  end
	  @styles_changed = []

	else
	  # should never be there!

	end
	@ep_plugin.log_info << "Setting Editpane properties"
      end

      def apply_editor_config(ep_slot)
	if @ep_plugin.properties['cursor_blinking']
	  ep_slot['actions/set_caret_period'].invoke(@ep_plugin.properties['cursor_blinking_period'])
	else
	  ep_slot['actions/set_caret_period'].invoke(0)
	end
	ep_slot['actions/set_caret_fore'].invoke(@ep_plugin.properties['cursor_fore'])
	ep_slot['actions/set_caret_width'].invoke(@ep_plugin.properties['cursor_width'])
	ep_slot['actions/set_wrap_mode'].invoke(@ep_plugin.properties['line_wraping'])
	ep_slot['actions/set_code_folding'].invoke(@ep_plugin.properties['code_folding'])
	ep_slot['actions/linenumbers_visible'].invoke(@ep_plugin.properties['line_numbers'])

	ep_slot['actions/indentation_guides_visible'].invoke(@ep_plugin.properties['indent_guides'])
	ep_slot['actions/eol_visible'].invoke(@ep_plugin.properties['eol'])
	ep_slot['actions/whitespace_visible'].invoke(@ep_plugin.properties['white_space'])
      end

      def apply_colors_fonts(ep_slot, all_styles=false)
	
	# determine what styles must be updated
	if all_styles
	  style_list = STYLES.keys
	else
	  style_list = @styles_changed
	end
	# apply fonts & colors to all editpanes - Make sure to
	# setup the default font first
	if style_list.include? 'DEFAULT'
	  ep_slot['actions/set_style'].invoke('DEFAULT',@ep_plugin.properties['style_default'])
	  ep_slot['actions/set_style_clear_all'].invoke()
	end
	(style_list - ['DEFAULT']).each do |style_name|
	  prop_name = 'style_'+style_name.downcase
	  ep_slot['actions/set_style'].invoke(style_name, @ep_plugin.properties[prop_name])
	end
      end

      def apply_all_config(ep_slot)
	apply_editor_config(ep_slot)
	apply_colors_fonts(ep_slot,true)
	@ep_plugin.log_info << "Setting All Editpane properties"
      end

      def init_all_config

	# main editor preference panel
	@ep_plugin.properties['cursor_blinking'] = true if @ep_plugin.properties['cursor_blinking'].nil?
	@ep_plugin.properties['cursor_blinking_period'] = 500 if @ep_plugin.properties['cursor_blinking_period'].nil?
	@ep_plugin.properties['cursor_fore'] = 0x000000 if @ep_plugin.properties['cursor_fore'].nil?
	@ep_plugin.properties['cursor_width'] = 1 if @ep_plugin.properties['cursor_width'].nil?
	@ep_plugin.properties['line_wraping'] = false if @ep_plugin.properties['line_wraping'].nil?
	@ep_plugin.properties['code_folding'] = true if @ep_plugin.properties['code_folding'].nil?
	@ep_plugin.properties['line_numbers'] = true if @ep_plugin.properties['line_numbers'].nil?
	@ep_plugin.properties['indent_guides'] = true if @ep_plugin.properties['indent_guides'].nil?
	@ep_plugin.properties['eol'] = false if @ep_plugin.properties['eol'].nil?
	@ep_plugin.properties['white_space'] = false if @ep_plugin.properties['white_space'].nil?
	@ep_plugin.properties['open_dir_policy'] = OPEN_DIR_CURRENT if @ep_plugin.properties['open_dir_policy'].nil?
  ft_slot = @plugin['/plugins/rubyide_tools_fox_file_browser/properties/FileTypes']
  ft_slot.data = "*.rb,*.rbw,*.xml,*.rhtml" if ft_slot.data.nil?

	# fonts & colors
	if @ep_plugin.properties['fxdefault_fontdesc'].nil?
	  @ep_plugin.properties['fxdefault_fontdesc'] = FXFont.new(@plugin['/system/ui/fox/FXApp'].data,STYLES['DEFAULT'].font, STYLES['DEFAULT'].size).getFont
	end
	@fxdefault_fontdesc = @ep_plugin.properties['fxdefault_fontdesc']
	STYLES.each_key do |style_name|
	  prop_name = 'style_'+style_name.downcase
	  @ep_plugin.properties[prop_name] ||= STYLES[style_name]
	end

      end

      # Create a new Style store for Ruby where user specific settings will be saved
      def init_styles      
        @styles = StyleStore.new('RubyStyles')
        STYLES.each_key { |style_name|
          prop_name = 'style_'+style_name.downcase
          @styles[style_name] = @ep_plugin.properties[prop_name].dup
        }        
      end

      ##
      # get_properties is a method called by the configurator plugin
      # whenever the configuration panel of a given plugin is dislayed
      # and the current settings must be displayed.
      #
      # config_slot: input parameter passed by the configurator plugin
      # in case there are several configuration pane for the same plugin
      #
      def get_config_properties(config_slot)

	ep_slot = @ep_plugin['/system/ui/current/EditPane']
	case config_slot.name
	when 'Editor'
	  @cb.check  = @ep_plugin.properties['cursor_blinking']
	  @cbms.text = @ep_plugin.properties['cursor_blinking_period'].to_s
	  @cfore.rgba= @ep_plugin.properties['cursor_fore']
	  @cw.value  = @ep_plugin.properties['cursor_width']
	  @lw.check  = @ep_plugin.properties['line_wraping']
	  @cf.check  = @ep_plugin.properties['code_folding']
	  @ln.check  = @ep_plugin.properties['line_numbers']
	  @ig.check  = @ep_plugin.properties['indent_guides']
	  @eol.check = @ep_plugin.properties['eol']
	  @ws.check  = @ep_plugin.properties['white_space']
	  @odp.currentItem = @ep_plugin.properties['open_dir_policy']
    @fel.text  = @plugin['/plugins/rubyide_tools_fox_file_browser/properties/FileTypes'].data

	when 'colors&fonts'
	  @ftn.text = @ep_plugin.properties['style_default'].font.gsub(/&/,'&&')
	  @fts.text = @ep_plugin.properties['style_default'].size.to_s
    init_styles
    reload_styles    

	else
	  # should never be there!

	end
	@ep_plugin.log_info << "Getting Editpane properties"
      end

      private

      # apply the color settings to the scintilla widget in the dialog box
      # Make sure to setup the default font first
      def reload_styles
        _set_controller_style('DEFAULT',@styles['DEFAULT'])
        @controller.set_style_clear_all
        @styles.each { |style| _set_controller_style(style.name, style) }
        @styles_changed = []
        # mimic a click on the first style in the list to get the
        # Ui updated
        onCmdShowStyle(@style_lb,nil,nil)
      end

      def _set_controller_style(style_name,style)
	@controller.set_style(style_name, style)
	@styles_changed << style_name
      end

      def _set_controller_default_style(style)
	_set_controller_style('DEFAULT', @styles['DEFAULT'])
	@controller.set_style_clear_all
	@styles.each { |style| _set_controller_style(style.name, style) }
      end

      def onCmdSelectEditorFont(sender, sel, ptr)
	fdb = FXFontDialog.new(@plugin['/system/ui/fox/FXMainWindow'].data, "Choose default font...")
	current_font = FXFont.new(@plugin['/system/ui/fox/FXApp'].data,@fxdefault_fontdesc)
	#puts "font desc: #{current_font.getFontDesc}, font string #{current_font.getFont}"
	fdb.setFontSelection(current_font.getFontDesc)
	if fdb.execute != 0
	  fontdesc = fdb.getFontSelection
	  @fxdefault_fontdesc = FXFont.new(@plugin['/system/ui/fox/FXApp'].data,fontdesc).getFont
	  @ftn.text = "#{fontdesc.face}".gsub(/&/,'&&')  # escape '&' otherwise FOX takes as a shortcut
	  @fts.text = (fontdesc.size/10).to_s

	  #redefine the default style, clear all styles in the controller and 
	  @styles['DEFAULT'] = Style.new(@styles['DEFAULT'].to_s+','+fxfont_to_style(fontdesc.face, fontdesc.size, fontdesc.slant, fontdesc.weight),'DEFAULT','Default style')
	  _set_controller_default_style(@styles['DEFAULT'])
	end
	return 1
      end

      def onCmdForeWell(sender, sel, ptr)
	#transform FOX rgb (which actually is bgr!!) into hexa string
	rgb = sender.rgba
	colour = sprintf("#%06X",((rgb & 0x0000FF) << 16)+(rgb & 0x00FF00)+((rgb >> 16) & 0x0000FF))

	# set new style in the sample code for immediate preview
	style_name = @style_lb.getItemData(@style_lb.currentItem)
	if (@styles[style_name].fore.to_s != colour)
	  @styles[style_name].fore = Colour.new(colour)
	  _set_controller_style(style_name, @styles[style_name])
	  if style_name == 'DEFAULT'
	    #redefine the default style, clear all styles in the controller and 
	    _set_controller_default_style(@styles['DEFAULT'])
	  end
	end
	return 1
      end

      def onCmdBackWell(sender, sel, ptr)
	#transform FOX rgb (which actually is bgr!!) into hexa string
	rgb = sender.rgba
	colour = sprintf("#%06X",((rgb & 0x0000FF) << 16)+(rgb & 0x00FF00)+((rgb >> 16) & 0x0000FF))

	# set new style in the sample code for immediate preview
	style_name = @style_lb.getItemData(@style_lb.currentItem)
	if (@styles[style_name].back.to_s != colour)
	  @styles[style_name].back = Colour.new(colour)
	  _set_controller_style(style_name, @styles[style_name])
	  if style_name == 'DEFAULT'
	    #redefine the default style, clear all styles in the controller and 
	    _set_controller_default_style(@styles['DEFAULT'])
	  end
	end
	return 1
      end

      def onCmdToggleBold(sender, sel, ptr)
	style_name = @style_lb.getItemData(@style_lb.currentItem)
	@styles[style_name].bold = sender.check
	_set_controller_style(style_name, @styles[style_name])
	if style_name == 'DEFAULT'
	  #redefine the default style, clear all styles in the controller and 
	  _set_controller_default_style(@styles['DEFAULT'])
	end
	return 1
      end

      def onCmdToggleItalic(sender, sel, ptr)
	style_name = @style_lb.getItemData(@style_lb.currentItem)
	@styles[style_name].italic = sender.check
	_set_controller_style(style_name, @styles[style_name])
	if style_name == 'DEFAULT'
	  #redefine the default style, clear all styles in the controller and 
	  _set_controller_default_style(@styles['DEFAULT'])
	end
	return 1
      end

      def onCmdToggleUnderline(sender, sel, ptr)
	style_name = @style_lb.getItemData(@style_lb.currentItem)
	@styles[style_name].underline = sender.check
	_set_controller_style(style_name, @styles[style_name])
	if style_name == 'DEFAULT'
	  #redefine the default style, clear all styles in the controller and 
	  _set_controller_default_style(@styles['DEFAULT'])
	end
	return 1
      end

      def onCmdShowStyle(sender, sel, ptr)
	style_name = @style_lb.getItemData(@style_lb.currentItem)
	@forewell.rgba = @styles[style_name].fore.to_foxrgba
	@backwell.rgba = @styles[style_name].back.to_foxrgba
	#printf("style_name: %s, fore: %08X, back: %08X\n",style_name,@forewell.rgba,@backwell.rgba)
	@bold_cbox.check = @styles[style_name].bold?
	@italic_cbox.check = @styles[style_name].italic?
	@underline_cbox.check = @styles[style_name].underline?
      end

      def onCmdCursorFore(sender, sel, ptr)
	# nothing to do for now
	return 1
      end

      def fxfont_to_style(face, size, slant, weight)
	style = "font:#{face},size:#{size/10}"

	if slant == FONTSLANT_REGULAR 
	  #style += ",notitalic"
	elsif slant == FONTSLANT_ITALIC || slant == FONTSLANT_OBLIQUE
	  style += ",italic"
	end

	if weight <= FONTWEIGHT_MEDIUM
	  #style += ",notbold"
	else
	  style += ",bold"
	end
	return style
      end
    end #Class EditPaneConfiguratorRenderer

  end #FreeRIDE
end #FoxRenderer


