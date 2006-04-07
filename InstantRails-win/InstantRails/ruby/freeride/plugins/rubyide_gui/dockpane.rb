# Purpose: Setup and initialize the core gui interfaces for the Dock panels
#
# $Id: dockpane.rb,v 1.4 2005/02/27 16:29:18 ljulliar Exp $
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
# Copyright (c) 200 Laurent Julliard. All rights reserved.
#

require 'rubyide_gui/component_manager'
require 'rubyide_gui/component'

module FreeRIDE
  module GUI

    ##
    # This is the manager class for dockpane components.
    #
    class DockPane < Component
      extend FreeBASE::StandardPlugin

      def DockPane.start(plugin)
        base_slot = plugin["/system/ui/components/DockPane"]
        ComponentManager.new(plugin, base_slot, DockPane)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, base_slot)
        setup(plugin, base_slot, nil)
      end
      
      ##
      # Dock this pane to the supplied dockbar
      #
      def dock(dockbar_name)
        @dockbar_name = dockbar_name
        dockbar_path = "/system/ui/components/DockBar/#{dockbar_name}"
        @bar = @base_slot[dockbar_path]
        @actions['dock'].invoke(dockbar_path)
      end

      ##
      # Undock this dockpane. Make it overlaping again
      #
      def undock
        @actions['undock'].invoke
        @bar.manager.hide
      end
        
      def show
        @actions['show'].invoke
        @base_slot["status"].data = 'opened'
        @bar.manager.show
      end
      
      def hide
        @actions['hide'].invoke
        @base_slot["status"].data = 'closed'
        @bar.manager.hide
      end

      def current?
        @actions['current?'].invoke
      end

      def hidden?
        @actions['hidden?'].invoke
      end

      def docked?
        @actions['docked?'].invoke
      end

      def docked=(is_docked)
        @actions['docked='].invoke(is_docked)
      end
    
      ##
      # Save the location of the undocked pane (size/position)
      #
      def save_location
        @actions['save_location'].invoke
      end

      ##
      # This method has been created mostly for the purpose of being
      # invoked from the plugin stop method. If an undocked plugin
      # uses combo boxes then when it crashed FreeRIDE when combo boxes
      # objects are released when FR stops. Reparenting the the frame to the
      # original dockpane avoids the crash. NOW THE QUESTION IS WHY DOES IT 
      # CRASH ???
      def reparent_to_dockpane
        @actions['reparent_to_dockpane'].invoke
      end

    end  # class DockPane
    
  end
end # module FreeRIDE
