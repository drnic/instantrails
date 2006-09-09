# Purpose: Setup and initialize the core gui interfaces
#
# $Id: menubar.rb,v 1.1.1.1 2002/12/20 17:27:31 richkilmer Exp $
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
    # This is the manager class for menubar components. A menubar
    # contains a list of menupanes. Each menupane specified as the
    # databus path to a menupane component.
    #
    class MenuBar < Component
      extend FreeBASE::StandardPlugin
      
      def MenuBar.start(plugin)
        base_slot = plugin["/system/ui/components/MenuBar"]
        ComponentManager.new(plugin, base_slot, MenuBar, 1)
        plugin.transition(FreeBASE::RUNNING)
      end
  
      def initialize(plugin, base_slot)
        setup(plugin, base_slot)
      end
  
      ##
      # Replaces this menubar's current menupane list with a new one.
      #
      def menuPanes=(menu_list)
        begin
          @base_slot.propagate_notifications = false;
          # remove any existing menupanes
          @base_slot.each_slot {|slot| slot.prune}
          index = 0
          menu_list.each do |menupane_path|
            @base_slot[index.to_s].data = menupane_path
            index += 1
          end
        rescue => error
          # any excetions stop here!
          @plugin.log_error << "Exception in MenuBar: #{error}"
        ensure
          @base_slot.propagate_notifications = true;
        end
        @base_slot.notify(:refresh) if @base_slot.attr_visible
      end
  
    end  # class MenuBar
    
  end
end # module FreeRIDE
