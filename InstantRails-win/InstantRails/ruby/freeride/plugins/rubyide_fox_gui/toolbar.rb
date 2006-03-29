# Purpose: Setup and initialize the core gui interfaces
#
# $Id: toolbar.rb,v 1.7 2004/12/03 21:24:02 ljulliar Exp $
#
# Authors:  Curt Hibbs <curt@hibbs.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Rich Kilmer. All rights reserved.
#

module FreeRIDE
  module FoxRenderer
    
    ##
    # This is the module that renders ToolBars using
    # FOX.
    #
    class ToolBar
      ICON_PATH = "/system/ui/icons/ToolBar"
      extend FreeBASE::StandardPlugin
      
      def ToolBar.start(plugin)
        
        # Start processing icons
        plugin[ICON_PATH].subscribe do |event, slot|
          if event == :notify_slot_add
            path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
            if FileTest.exist?(path)
              slot.data = Fox::FXPNGIcon.new(slot['/system/ui/fox/FXApp'].data, File.open(path, "rb").read)
              slot.data.create
            end
          end
        end
        
        component_slot = plugin["/system/ui/components/ToolBar"]
        
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end
        
        component_slot.each_slot { |slot| slot.notify(:notify_slot_add) }
        
        # Now only is this plugin running
        plugin.transition(FreeBASE::RUNNING)
      end
      
      
      ##
      # Each instance of this class is responsible for rendering an menubar component
      #
      class Renderer
        include Fox
        attr_reader :plugin
        def initialize(plugin, slot)
          @plugin = plugin
          @slot = slot
          @plugin.log_info << "ToolBar #{@slot.name} started"
          
          # Currently we only allow one menubar
          @main_window = @plugin["/system/ui/fox/FXMainWindow"].data
          @toolbar = @plugin["/system/ui/fox/FXToolBar"].data
          @slot['groups'].subscribe { |event, slot| update(event, slot) }
          # Fake notification events for any slots that existed before we subscribed
          @cmd_mgr = plugin["/system/ui/commands"].manager
          @icons = {}
          plugin.properties.each_property("Icons") do |icon, command|
            cmd = @cmd_mgr.command(command)
            cmd.icon = "#{ICON_PATH}/#{icon}" if cmd
          end
          update(:notify_data_set, @slot['groups'])
        end
        
        # Called whenever the menubar may need to be updated.
        def update(event, slot)
          return if event != :notify_data_set
          return if slot.parent.name == "ToolBar"
          (@toolbar.numChildren-1).downto(0) do |i|
            button = @toolbar.childAtIndex(i)
            @toolbar.removeChild(button)
          end
          
          first = true
          @slot.manager.each_group do |group| 
            if (@slot.manager.command_count(group) > 0) && !first
              #FXFrame.new(@toolbar, LAYOUT_TOP | LAYOUT_LEFT | LAYOUT_FIX_WIDTH | LAYOUT_FIX_HEIGHT, 0,0,7,20)
              #FXVerticalSeparator.new(@toolbar, SEPARATOR_GROOVE|LAYOUT_FILL_Y)
              button = FXButton.new(@toolbar, "\t\t", 
                @plugin["#{ICON_PATH}/separator"].data, nil, 0, 
                LAYOUT_TOP | LAYOUT_LEFT |LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT,0,0,10,22)
	      button.create
              #button.disable
            end
            first = false
            @slot.manager.each_command(group) do |command|
              cmd = @cmd_mgr.command(command)
              unless cmd.icon
                cmd.icon = "#{ICON_PATH}/empty"
              end
              icon = @plugin[cmd.icon].data
              
              button = FXButton.new(@toolbar, "\t#{cmd.text.gsub(/\&/, '')}\t#{cmd.description}", 
                icon, nil, 0, 
              BUTTON_TOOLBAR|BUTTON_NORMAL,0,0,22,22)
              button.create
              button.connect(SEL_COMMAND) {cmd.invoke}
            end
          end
          @toolbar.forceRefresh
        end
      end 
    end
  end
end  

