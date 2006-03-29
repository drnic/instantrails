# Purpose: Setup and initialize the FR Configurator
#
# $Id: configurator.rb,v 1.1 2004/06/13 21:26:22 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
#
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


module FreeRIDE; module GUI

##
# This module defines the FreeRIDE Configurator
#
class Configurator < Component
  extend FreeBASE::StandardPlugin

  def self.start(plugin)

    # Manage the configurators in a pool. 
    base_slot = plugin["/system/ui/components/Configurator"]
    ComponentManager.new(plugin, base_slot, Configurator)

    # Create the Debug menu item and associate a command with it
    # When the command is invoked create a new debugger session
    # unless there is one already and start it
    cmd_mgr = plugin['/system/ui/commands'].manager
    
    configurator = nil
    session = nil
    cmd = cmd_mgr.add("App/Edit/Configurator", "&Preferences...") do |cmd_slot|
      configurator = base_slot.manager.add unless configurator
      configurator.manager.start
    end
    
    # Insert the configurator menu item in the run menu and bind it
    # to the F?? key
    editmenu = plugin["/system/ui/components/MenuPane/Edit_menu"].manager
    editmenu.add_command("App/Edit/Configurator")
    
    key_mgr = plugin['/system/ui/keys'].manager
    #key_mgr.bind("/App/Run/configurator", :F10)

    # Now only is the plugin running
    plugin.transition(FreeBASE::RUNNING)
  end

  ##
  # Instantiate a new configurator session . Only one session at a time for now
  #
  def initialize(plugin, base_slot)
    setup(plugin, base_slot)
    @cmd_mgr = plugin["/system/ui/commands"].manager
    @plugin['/system/ui/current'].link('Configurator',base_slot)
    @plugin.log_info << "Configurator created #{base_slot.path}"
 end

  ##
  # Prompt a message in the status bar
  #
  def status(msg)
    @plugin['/system/ui/current/StatusBar/actions/prompt'].invoke(msg)
  end

  ##
  # Start the configurator.
  # Delete all slots in the Configurator and rebuild the list of
  # plugin configurators in case some new plugins have been 
  # loaded
  #
  def start
    @actions['start'].invoke
    show_pane()
    @plugin.log_info << "Configurator started #{@base_slot.path}"
  end


  ##
  #  Show the configurator. Actually relayed to the renderer
  #
  #  Input:: config_slot the config to show when first when config dialog box
  #  is displayed
  #  Return:: none
  #
  def show_pane(config_slot=nil)
    @actions['show_pane'].invoke(config_slot)
  end

end

end; end
