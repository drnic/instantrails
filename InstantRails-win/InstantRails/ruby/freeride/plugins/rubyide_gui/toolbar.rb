# Purpose: Setup and initialize the core gui interfaces for the Dock panels
#
# $Id: toolbar.rb,v 1.3 2002/12/20 21:05:12 richkilmer Exp $
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
    class ToolBar < Component
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        base_slot = plugin["/system/ui/components/ToolBar"]
        ComponentManager.new(plugin, base_slot, ToolBar, 1)
        toolbar = base_slot.manager.add
        plugin['/system/ui/current'].link("ToolBar", toolbar)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, base_slot)
        setup(plugin, base_slot, nil)
        @groups = []
        @plugin["/plugins/rubyide_gui-component_manager/properties/AppFrame/ToolBar"].each_slot do |group|
          @groups << [group.data]
          group.each_slot do |item|
            @groups.assoc(group.data) << item.data
          end
        end
        @base_slot['groups'].data = @groups
      end
      
      def add_group(name, before=nil)
        if after
          @groups.each_with_index do |group, index|
            if group[0]==before
              @groups[(index+1)..-1] = @groups[index..-1]
              @groups[index] = [name]
              break
            end
          end
        else
          @groups << [name]
        end
        @base_slot['groups'].data = @groups
      end
      
      def remove_group(name)
        @groups.each_with_index do |group, index|
          if group[0]==name
            @groups[index]=nil
            @groups.compact!
            break
          end
        end
        @base_slot['groups'].data = @groups
      end
      
      def add_command(groupName, command, after=nil)
        group = @groups.assoc(groupName)
        if group
          if after
            found = false
            group.each_with_index do |item, index|
              if item==after
                group[(index+1)..-1] = group[index..-1]
                group[index] = command
                found = true
                break
              end
            end
            group << command unless found
          else
            group << command
          end
        end
        @base_slot['groups'].data = @groups
      end
      
      def remove_command(groupName, item)
        group = @groups.assoc(groupName)
        group.delete(item) if group
        @base_slot['groups'].data = @groups
      end
      
      def each_group
        @groups.each {|group| yield group[0]}
      end
      
      def each_command(groupName)
        group = @groups.assoc(groupName)
        if group
          group[1..-1].each {|item| yield item}
        end
      end
      
      def command_count(groupName)
        group = @groups.assoc(groupName)
        if group
          return group.size - 1
        end
      end
      
    end
    
  end
end
