# Purpose: Setup and initialize the core gui interfaces
#
# $Id: appframe.rb,v 1.1.1.1 2002/12/20 17:27:31 richkilmer Exp $
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

require 'rubyide_gui/component_manager'
require 'rubyide_gui/component'

module FreeRIDE
  module GUI
  
    ##
    # This is the manager class for application-frame components.
    # An application-frame is the main FreeRIDE window.
    #
    # Currently, there can only be one application-frame -- but this
    # is a temporary restriction that will be removed in the future.
    #
    class AppFrame < Component
      extend FreeBASE::StandardPlugin
    
      def AppFrame.start(plugin)
        base_slot = plugin["/system/ui/components/AppFrame"]
        ComponentManager.new(plugin, base_slot, AppFrame, 1)
        plugin.transition(FreeBASE::RUNNING)
      end
    
      def initialize(plugin, base_slot)
        setup(plugin, base_slot)
      end
    end  # class AppFrame

  end
end 
