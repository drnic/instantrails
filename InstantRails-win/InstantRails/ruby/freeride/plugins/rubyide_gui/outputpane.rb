# Purpose: Setup and initialize the core gui interfaces for the Dock panels
#
# $Id: outputpane.rb,v 1.3 2004/11/20 20:55:51 ljulliar Exp $
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
    class OutputPane < Component
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        base_slot = plugin["/system/ui/components/OutputPane"]
        ComponentManager.new(plugin, base_slot, OutputPane, 1)
        output = base_slot.manager.add
        plugin['/system/ui/current'].link("OutputPane", output)
        
        plugin.transition(FreeBASE::RUNNING)
        plugin.log_info << "OutputPane plugin started"
      end
      
      def initialize(plugin, base_slot)
        setup(plugin, base_slot, nil)
      end
      
      def show
        @actions['show'].invoke
      end
      
      def hide
        @actions['hide'].invoke
      end
      
      def set(name, text)
        @actions['set'].invoke(name, text)
      end
      
      def append(name, text)
        @actions['append'].invoke(name, text)
      end
      
      def clear(name)
        @actions['clear'].invoke(name)
      end
      
      def toggle
        @actions['toggle'].invoke
      end

      def attach_input(method)
	@actions['attach_input'].invoke(method)
      end

    end
    
  end
end
