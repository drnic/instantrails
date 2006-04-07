# Purpose: Setup and initialize the Status Bar interface
#
# $Id: statusbar.rb,v 1.1 2003/03/23 22:27:01 ljulliar Exp $
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
    # This is the manager class for the status bar components.
    # Only one status bar for now.
    class StatusBar < Component
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        base_slot = plugin["/system/ui/components/StatusBar"]
        ComponentManager.new(plugin, base_slot, StatusBar, 1)
        statusbar = base_slot.manager.add
        plugin['/system/ui/current'].link("StatusBar", statusbar)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, base_slot)
        setup(plugin, base_slot, nil)
      end
            
    end
    
  end
end
