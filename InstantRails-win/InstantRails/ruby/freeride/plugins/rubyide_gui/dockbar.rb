# Purpose: Setup and initialize the core gui interfaces for the Dock bars
#
# $Id: dockbar.rb,v 1.2 2003/05/02 21:14:27 ljulliar Exp $
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
    # This is the manager class for dockbar components.
    #
    class DockBar < Component
      extend FreeBASE::StandardPlugin
      
      def DockBar.start(plugin)
        base_slot = plugin["/system/ui/components/DockBar"]
        ComponentManager.new(plugin, base_slot, DockBar)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, base_slot)
        setup(plugin, base_slot)
      end
      
      ##
      # Attach a given dockpane in a given dock and return the path
      # of the dock the plugin is attached to.
      #
      def attach(dockpane_path)
        @actions['attach'].invoke(dockpane_path)
      end
      
      ##
      # Remove a given plugin from the DockBar. Would typically
      # happen when the plugin is closed.
      #
      def detach(dockpane_path)
        @actions['detach'].invoke(dockpane_path)
      end
      
      ##
      # Hide this DockBar
      #
      def hide
        @actions['hide'].invoke
      end
      
      ##
      # Show this DockBar
      #
      def show
        @actions['show'].invoke
      end

      ##
      # Return the currently visible (active) dockpane
      # in this dockbar
      #
      def current
        @actions['current'].invoke
      end
       
    end
    
  end
end
