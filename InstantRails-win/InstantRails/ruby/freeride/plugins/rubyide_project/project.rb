# Purpose: Holds information regarding a FreeRIDE project
#
# $Id: project.rb,v 1.2 2003/09/01 21:42:11 ljulliar Exp $
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
# Copyright (c) 2002 Rich Kilmer All rights reserved.
#
require 'ftools'

module FreeRIDE
  module Tools
    class ProjectManager
    
      class Project
        attr_reader :name, :properties_path, :properties
        def initialize(plugin, properties_path, name=nil)
          @plugin = plugin
          @name = name
          @properties_path = properties_path
          @plugin["/project/current"].data = properties_path
          @properties_slot = @plugin["/project/current/properties"]
          unless File.absolute_path?(@properties_path)
            @properties_path = File.join(@plugin.plugin_configuration.base_user_path, @properties_path)
          end
          #File.makedirs(File.dirname(@properties_path))
          @plugin["/project/current"].manager = self
          @properties = FreeBASE::Properties.new("rubyide_project-project", "1.0", @properties_slot, @properties_path)
          if @name
            @properties['name'] = @name unless @properties['name']==@name
          else
            @name = @properties['name']
          end
          open
        end
        
        def close
          @subscription.cancel
          @subscription = nil
          done = @plugin['/system/ui/commands'].manager.command('App/File/CloseAll').invoke
          if done
            @plugin['/project/current'].prune
          else
            track_editpanes
          end
          return done
        end
        
        def open
          @properties_slot['state/open_files'].each_slot do |slot|
            ep_slot = @plugin['/system/ui/commands'].manager.command('App/File/Load').invoke(slot.data)
            slot.prune if ep_slot.nil?
          end
          track_editpanes
        end
        
        def track_editpanes
          # Subscribe to the editpane slot to render any newly created edit pane
          @subscription = @plugin["/system/ui/components/EditPane"].subscribe do |event, slot|
            if slot.parent.name == "EditPane"
              if (event == :notify_data_set)
                @properties["state/open_files/#{slot.name}"] = slot.data
              elsif (event == :notify_slot_prune)
                @properties_slot['state/open_files'].each_slot do |prop_slot|
                  @properties.prune("state/open_files/#{prop_slot.name}") if slot.data == prop_slot.data
                end
              end
            end
          end
        end
        
      end
      
    end
  end
end

