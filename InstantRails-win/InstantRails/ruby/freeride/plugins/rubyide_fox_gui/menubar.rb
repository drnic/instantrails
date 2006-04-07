# Purpose: Setup and initialize the core gui interfaces
#
# $Id: menubar.rb,v 1.3 2004/12/03 21:24:02 ljulliar Exp $
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
  module FoxRenderer
    
    ##
    # This is the module that renders menubars using
    # FOX.
    #
    class MenuBar
      extend FreeBASE::StandardPlugin
      
      def MenuBar.start(plugin)
      
        component_slot = plugin["/system/ui/components/MenuBar"]
        
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
          @plugin.log_info << "MenuBar #{@slot.name} started"
          
          # Currently we only allow one menubar
          @main_window = @plugin["/system/ui/fox/FXMainWindow"].data
          @menubar = @plugin["/system/ui/fox/FXMenuBar"].data
          @slot.subscribe do |event, slot| 
            update(slot) if event==:notify_data_set && slot.parent.name!="MenuBar"
          end
          # Fake notification events for any slots that existed before we subscribed
          @slot.each_slot { |slot| slot.notify(:notify_data_set) }
        end
        
        # Called whenever the menubar may need to be updated.
        def update(slot)
          name = @plugin[slot.data].data
          menu = @plugin[slot.data].attr_FXMenuPane
          title = FXMenuTitle.new(@menubar, name, nil, menu)
          title.create
          @plugin[slot.data].attr_FXMenuTitle = title
        end
      end  # class Renderer
      
    end
    
  end
end  

