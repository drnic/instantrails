# Purpose: Setup and initialize the dock bar gui interfaces
#
# $Id: fox_debugger_configurator.rb,v 1.6 2005/02/20 08:04:01 ljulliar Exp $
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
	  FXLabel.new(group1_frm,"Path to ruby:",nil,JUSTIFY_LEFT|LAYOUT_TOP|LAYOUT_LEFT)
	  @ptr = FXTextField.new(group1_frm, 2, nil, 0, (LAYOUT_TOP|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN|FRAME_THICK))
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

	  # Sample sub-items (not used)
	  pcfg['subitem1'].attr_icon = nil
	  pcfg['subitem1'].attr_label = 'An unused sub-pane'
	  pcfg['subitem1'].attr_description = 'A sample configuration sub-pane'
	  pcfg['subitem1'].attr_frame = nil
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
	  @dbg_plugin.properties['path_to_ruby'] = @ptr.text
	  @dbg_plugin.properties['cmd_line_options'] = @clo.text
	  @dbg_plugin.properties['working_dir'] = @wd.text
	  @dbg_plugin.properties['config_before_running'] = @dbr.check
	  @dbg_plugin.properties['save_before_running'] = @sbr.check
	  @dbg_plugin.properties['run_in_terminal'] = @rit.check
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
	  @ptr.text = @dbg_plugin.properties['path_to_ruby'] || ""
	  @clo.text = @dbg_plugin.properties['cmd_line_options'] || ""
	  @wd.text =  @dbg_plugin.properties['working_dir'] || ""
	  @dbr.check = @dbg_plugin.properties['config_before_running'] || false
	  @sbr.check = @dbg_plugin.properties['save_before_running'] || false
	  @rit.check = @dbg_plugin.properties['run_in_terminal'] || false
	  @dbg_plugin.log_info << "Getting Debugger/Run properties"
	end

      end #Class ConfiguratorRenderer

    end
  end
end
