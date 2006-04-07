# Purpose: Setup and initialize the core gui interfaces
#
# $Id: component.rb,v 1.1.1.1 2002/12/20 17:27:31 richkilmer Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
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
  module GUI
    
    ##
    # Parent class for all components
    #
    class Component
      def setup(plugin, base_slot, data=base_slot.name)
        @plugin = plugin
        @base_slot = base_slot
        @cmd_mgr = plugin['/system/ui/commands'].manager
        @actions = @base_slot['actions']
        @base_slot.manager = self
        @base_slot.data = data if data
        @plugin.log_debug << "#{self.class.to_s} component created for #{@base_slot.name}"
      end
    end
    
  end
end # module FreeRIDE
