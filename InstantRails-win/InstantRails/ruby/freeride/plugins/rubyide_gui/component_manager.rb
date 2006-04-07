# Purpose: Setup and initialize the core gui interfaces
#
# $Id: component_manager.rb,v 1.3 2005/09/16 07:48:24 ljulliar Exp $
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
# Copyright (c) 2001 Curt Hibbs. All rights reserved.
#

module FreeRIDE
  module GUI
  
    ##
    # This is the plugin that sets-up, lays-out, and initializes the
    # FreeRIDE GUI.
    #
    class ComponentManager
      extend FreeBASE::StandardPlugin
      
      ##
      # This is the plugin-method that sets-up, lays-out, and initializes the
      # FreeRIDE GUI.  The definition for the frames, menupanes is defined in
      # GuiSetup.xml.
      # This is the manager class for all component pools.
      #
      # When an instances of this class is created to manage a particular
      # component pool, it is given the class that is used to manage
      # components of this pool. Whenever a new slot is created within
      # this component pool, and instance of the manager class is created
      # and assigned as the manager of the new slot.
      #
      def ComponentManager.start(plugin)
        properties = plugin.properties
        pslot = properties.base_slot
        if pslot.has_child?("AppFrame")
          
          appFrameSlot = plugin["/system/ui/components/AppFrame"].manager.add("main")
          appFrameSlot.data = pslot["AppFrame/Attributes/text"].data
          
          menus = []
          pslot["AppFrame/MenuBar/MenuPanes"].each_slot do |menu_slot|
            menu = plugin["/system/ui/components/MenuPane"].manager.add(menu_slot['Attributes/id'].data)
            menus << menu.path
            menu.data = menu_slot["Attributes/text"].data
            menu.attr_visible = menu_slot["Attributes/visible"].data
            if menu_slot.has_child?("Commands")
              commands = []
              menu_slot["Commands"].each_slot do |command_slot|
                if command_slot.data!="SUBMENU"
                  commands << command_slot.data
                else
                  submenu_hash = {}
                  submenu_hash["Text"]     = command_slot["Text"]
                  submenu_hash["Commands"] = command_slot["Commands"]
                  commands << submenu_hash
                end
              end
              menu.manager.commands = commands
            end
          end
          menubar = plugin["/system/ui/components/MenuBar"].manager.add
          menubar.manager.menuPanes = menus
          menubar.attr_visible = true
          pslot["AppFrame/DockBars"].each_slot do |dockbar_slot|
            plugin["/system/ui/components/DockBar"].manager.add(dockbar_slot.name)
          end
        end
        
        # Now only is this plugin running
        plugin.transition(FreeBASE::RUNNING)
      end
      
      attr_reader :plugin, :base_slot, :component_class
      attr_accessor :limit
      
      def initialize(plugin, base_slot, component_class, limit=0)
        @plugin = plugin
        @base_slot = base_slot
        @base_slot.manager = self
        @component_class = component_class
        @count = 0
        @limit = limit
      end
      
      def add(id = nil)
        raise "Cannot create more than #{@limit} #{@component_class}'s" if (@limit > 0 && @limit==@count)
        @count += 1
        id ||= @count
        componentSlot = @base_slot["#{id}"]
        @component_class.new(@plugin, componentSlot)
        componentSlot
      end
      
      def remove(id)
        raise "Not yet implemented"
      end
      
      def each_slot
        @base_slot.each {|slot| yield slot}
      end
    end
    
  end
end # module FreeRIDE
