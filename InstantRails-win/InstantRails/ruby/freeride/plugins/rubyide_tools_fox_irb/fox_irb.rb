# Purpose: Run irb in a an output pane
#
# $Id: fox_irb.rb,v 1.6 2006/05/27 15:18:31 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent at moldus dot org>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Laurent Julliard All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

require 'rubyide_tools_fox_irb/fxirb'

module FreeRIDE; module GUI
  class IRB < Component
    extend FreeBASE::StandardPlugin
    include Fox

    def self.start(plugin)

      # There can only be one IRB session at a time
      base_slot = plugin["/system/ui/components/IRB"]
      ComponentManager.new(plugin, base_slot, IRB, 1)

      @@irb = nil

      # Handle icons
      plugin['/system/ui/icons/IRB'].subscribe do |event, slot|
        if event == :notify_slot_add
          app = plugin['/system/ui/fox/FXApp'].data
          path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
          if FileTest.exist?(path)
            slot.data = Fox::FXPNGIcon.new(app, File.open(path, "rb").read)
            slot.data.create
          end
        end
      end

      # Create the Run IRB command and show it in the 
      # "view" area of the toolbar rather than the "run" area
      cmd_mgr = plugin["/system/ui/commands"].manager
      cmd_irb = cmd_mgr.add("App/Run/RunIRB","&IRB") do |cmd_slot|
        @@irb = IRB.new(plugin, base_slot) unless @@irb
        @@irb.show
      end
      plugin["/system/ui/keys"].manager.bind("App/Run/RunIRB", :F6)
      cmd_irb.icon = "/system/ui/icons/IRB/irb"
      plugin["/system/ui/current/ToolBar"].manager.add_command("View", "App/Run/RunIRB")

      
      # Insert the run IRB command in the Run menu
      runmenu = plugin["/system/ui/components/MenuPane/Run_menu"].manager
      runmenu.add_command("App/Run/RunIRB")    

      # Create the "view IRB" in the View menu to hide/show the IRB pane
      cmd_view_irb = cmd_mgr.add("App/View/IRB","&IRB","View IRB shell") do |cmd_slot|
	@@irb.toggle if @@irb
      end

      # manage availability of the IRB View menu
      cmd_view_irb.availability = plugin['/system/ui/current'].has_child?('IRB')
      cmd_view_irb.manage_availability do |command|
	plugin['/system/ui/current'].subscribe do |event, slot|
	  if slot.name=="IRB"
	    case event
	    when :notify_slot_link
	      command.availability = true
	    when :notify_slot_unlink
	      command.availability = false
	    end
	  end
	end
      end

      # and attach it to the View menu pane
      viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
      viewmenu.add_command("App/View/IRB")
      viewmenu.uncheck("App/View/IRB")

      # Start the IRB plugin if it was there at the last session
      plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
        if slot.data == true
          if plugin.properties["Open"]
            cmd_irb.invoke
          end
        end
      end
      
      plugin.transition(FreeBASE::RUNNING)
    end


    def initialize(plugin, base_slot)
      @plugin = plugin
      @viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
      @plugin['/system/ui/current'].link('IRB',base_slot)

      # Create the IRB text frame and reparent it to the dockpane
      main_window = plugin["/system/ui/fox/FXMainWindow"].data
      frm = FXIrb.init(main_window, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP|TEXT_SHOWACTIVE)
      frm.on_exit {
        self.appendText("IRB exited. Restarting...\n")
      }
      frm.hide
      frm.create

      # Dock the IRB frame now that everything is ready
      @dockpane_slot = plugin['/system/ui/components/DockPane'].manager.add("IRB")
      @dockpane_slot.data = frm
      @dockpane_slot.manager.dock('south')
     
      # When the dockpane informs us that it is opened or closed
      # adjust the menu item and properties accordingly 
      @dockpane_slot["status"].subscribe do |event, slot|
        if event == :notify_data_set
          if @dockpane_slot["status"].data == 'opened'
            @checked = true
            @viewmenu.check("App/View/IRB")
            @plugin.properties["Open"] = true
          elsif @dockpane_slot["status"].data == 'closed'
            @viewmenu.uncheck("App/View/IRB")
            @checked = false
            @plugin.properties["Open"] = false
          end
        end
      end

      plugin.log_info << "IRB renderer created"
    end

    def toggle
      # hide it if visible, show it if invisible
      @checked ? hide : show
    end

    def show
      @dockpane_slot.manager.show
    end

    def hide
      @dockpane_slot.manager.hide
    end

  end

end; end
