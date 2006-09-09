# Purpose: Setup and initialize the dock bar gui interfaces
#
# $Id: fox_debugger_configurator.rb,v 1.12 2006/06/04 09:59:02 jonathanm Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
# Contributors: Richard Kilmer <rich@infoether.com>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Laurent Julliard. All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

require 'fox12/colors'
require 'rubyide_tools_fox_debugger/fox_ruby_configurator'

module FreeRIDE
  module FoxRenderer

    module DebuggerRenderFox
      include Fox

      class DebuggerConfiguratorRenderer

	include Fox
	ICON_PATH = "/system/ui/icons/Debugger"

	def initialize(plugin)
	  @plugin = plugin
	  @dbg_plugin = @plugin['/plugins/rubyide_tools_debugger'].manager
    
	  main = plugin['/system/ui/fox/FXMainWindow'].data

	  # create the config pane UI. Parent it to the main window for now
	  #
	  config_pane = FXVerticalFrame.new(main, FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	  group1 = FXGroupBox.new(config_pane, "Runtime Parameters",
                   GROUPBOX_TITLE_LEFT|FRAME_RIDGE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	  group1_frm = FXVerticalFrame.new(group1, FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	  FXLabel.new(group1_frm,"Ruby interpreter to use:",nil,JUSTIFY_LEFT|LAYOUT_TOP|LAYOUT_LEFT)
	  @il = FXComboBox.new(group1_frm, 0, nil, 0, COMBOBOX_NORMAL|LAYOUT_FILL_X|FRAME_THICK)
    @il.setNumVisible(4)
	  FXLabel.new(group1_frm,"Command line options:",nil,JUSTIFY_LEFT|LAYOUT_TOP|LAYOUT_LEFT)
	  @clo = FXTextField.new(group1_frm, 2, nil, 0, (LAYOUT_TOP|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN|FRAME_THICK))
	  FXLabel.new(group1_frm,"Working directory:",nil,JUSTIFY_LEFT|LAYOUT_TOP|LAYOUT_LEFT)
	  @wd = FXTextField.new(group1_frm, 2, nil, 0, (LAYOUT_TOP|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN|FRAME_THICK))
	  @sbr = FXCheckButton.new(config_pane, "Save files before running/debug...", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	  @dbr = FXCheckButton.new(config_pane, "Display dialog before running/debug... (not implemented yet)", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
	  @dbr.disable
	  @rit = FXCheckButton.new(config_pane, "Run process in terminal", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)

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

	  pcfg = plugin["configurator/Debugger"]
	  pcfg.attr_icon = plugin[ICON_PATH+'/startDebugger'].data
	  pcfg.attr_label = 'Debugger/Run'
	  pcfg.attr_description = 'Debugger/Run Settings'
	  pcfg.attr_frame = config_pane

    # Construct the ruby-interpreter configuration sub-panel
	  @ruby_configurator = RubyConfiguratorRenderer.new(plugin)
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
    dbg_props = @plugin['/project/active/default'].manager.properties
    
	  case config_slot.name
	  when 'Debugger'
    default_interpreter = @il.getItemText(@il.getCurrentItem)
    dbg_props['default_interpreter'] = default_interpreter
    @dbg_plugin.properties['interpreters'].each do |key, val|
      if key == default_interpreter
        dbg_props['path_to_ruby'] = val["command"]
        break
      end
    end
	  dbg_props['cmd_line_options'] = @clo.text
	  dbg_props['working_dir'] = @wd.text
    
	  dbg_props['config_before_running'] = @dbr.checkState == 1
	  dbg_props['save_before_running'] = @sbr.checkState == 1
	  dbg_props['run_in_terminal'] = @rit.checkState == 1
    dbg_props.save
	  when 'Ruby'
	    @ruby_configurator.save_properties
	  end
	  @dbg_plugin.log_info << "Setting Debugger/Run properties"
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
    dbg_props = @plugin['/project/active/default'].manager.properties
    
	  case config_slot.name
    when 'Debugger'
      @il.clearItems
      if @dbg_plugin.properties['interpreters']
        @dbg_plugin.properties['interpreters'].each do |key, val|
          @il.appendItem(key)
        end
      end
      default_interpreter = dbg_props['default_interpreter']
      if default_interpreter
        @il.getNumItems.times do |idx|
          if @il.getItem(idx) == default_interpreter
            @il.setCurrentItem(idx)
            break
          end
        end
      end
      @clo.text = dbg_props['cmd_line_options'] || ""
      @wd.text =  dbg_props['working_dir'] || ""
      @dbr.check = dbg_props['config_before_running'] || false
      @sbr.check = dbg_props['save_before_running'] || false
      @rit.check = dbg_props['run_in_terminal'] || false
	  when 'Ruby'
      @ruby_configurator.load_properties
	  end
	  @dbg_plugin.log_info << "Getting Debugger/Run properties"
	end

  ##
  #
  def modified?(config_slot)
    case config_slot.name
    when 'Debugger'
      return !( cmp_prop('default_interpreter', @il.getItemText(@il.getCurrentItem)) and
        cmp_prop('cmd_line_options', @clo.text) and
        cmp_prop('working_dir', @wd.text) and
        cmp_prop('config_before_running', @dbr.check, false) and
        cmp_prop('save_before_running', @sbr.check, false)   and
        cmp_prop('run_in_terminal', @rit.check, false)
      )
    when 'Ruby'
      return @ruby_configurator.modified?
    end
  end

  ##
  # Method compares the property with name prop_name to val
  # if the named property is nil, then val is compared to the default value
  def cmp_prop(prop_name, val, default='')
    p = @plugin['/project/active/default'].manager.properties[prop_name]
    return val==p if p
    return val==default
  end

      end #Class ConfiguratorRenderer

    end
  end
end
