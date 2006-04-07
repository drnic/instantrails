# Purpose: Holds information regarding a FreeRIDE project
#
# $Id: project.rb,v 1.6 2005/12/16 11:11:40 jonathanm Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors: Jonathan Maasland <nochoice AT xs4all.nl>
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
  
    class Project
      attr_reader :name, :properties_path, :properties, :ep_slots
      OpenFilesPropPath = 'properties/state/open_files'
      
      def initialize(project_slot, properties_path, name=nil)
        @slot = project_slot
        @name = name
        @properties_path = properties_path
        
        @slot["."].data = properties_path
        @slot.manager = self
        
        # Rebuild the properties object if necessary
        if @slot.has_child?('properties')
          @properties = @slot['properties'].manager
        else
          @properties = 
  FreeBASE::Properties.new("rubyide_project-project", "1.0", @slot['properties'], @properties_path)
        end
        if @name
          @properties['name'] = @name unless @properties['name']==@name
        else
          @name = @properties['name']
        end
        
        @ep_slots = []
        @slot[OpenFilesPropPath].data = [] if @slot[OpenFilesPropPath].data.nil?
        
        # The default project will have a link-slot /project/active/default to it's /project/active slot
        if name == "Default Project"
          @slot["/project/active"].link("default", @slot.name)
        end
        
        reopen_files
        @opened = true
      end
      
      def open?
        return @opened
      end
      
      # Close all edit-panes associated with this project
      def close
        return true unless @opened
        done = true 
        @ep_slots.clone.each do |ep_slot|
          if ep_slot.manager.close != "cancel"
            @ep_slots.delete(ep_slot)
          else
            done = false
            break
          end
        end
        @opened = false if done
        return done
      end
      
      # Attach a newly opened Editpane to this project
      def attach_editpane(ep_slot)
        if ep_slot['actions/get_project'].invoke != nil
          ep_slot['actions/get_project'].invoke.detach_editpane(ep_slot)
        end
        @ep_slots << ep_slot
        ep_slot['actions/set_project'].invoke(self)
      end
      
      def detach_editpane(ep_slot)
        @ep_slots.delete(ep_slot)
        ep_slot['actions/set_project'].invoke(nil)
      end
      
      # Open all previously opened files.
      def reopen_files
        files = @slot[OpenFilesPropPath].data
        @slot[OpenFilesPropPath].data.each do |file|
          ep_slot = @slot['/system/ui/commands'].manager.command('App/File/Load').invoke(file)
          attach_editpane(ep_slot)
        end
      end
      
      # Open file and return the editpane-slot. If the file was already loaded in an
      # editpane it is automatically selected and returned.
      def open_file(filename)
        ep_slot = @slot['/system/ui/commands'].manager.command('App/File/Load').invoke(filename)
        #return ep_slot if @slot[OpenFilesPropPath].data.index(filename)
        if ep_slot
          @slot[OpenFilesPropPath].data << filename
          @slot[OpenFilesPropPath].data.uniq!
          @properties.save
          attach_editpane(ep_slot)
        end
        ep_slot
      end
      
      def close_ep(editpane_slot)
        ep = nil
        @ep_slots.each do |slot|
          if slot.data == editpane_slot.data
            if editpane_slot.manager.close == "yes"
              @ep_slots.delete(slot)
              @slot[OpenFilesPropPath].data.delete(slot.data)
              @properties.save
            end
            break
          end
        end
      end
      
    end
    
  end
end
