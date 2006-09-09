# Purpose: Manages projects in FreeRIDE
#
# $Id: project_manager.rb,v 1.6 2006/06/04 09:59:02 jonathanm Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors: Jonathan Maasland <nochcoice @ xs4all.nl>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Rich Kilmer All rights reserved.
#

require 'rubyide_project/project'
require 'rubyide_project/new_project_dialog'

module FreeRIDE
  module Tools
    class ProjectManager
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        @@last_index = 0  # Maybe we might have a different solution for this one?
        ProjectManager.new(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin)
        @plugin = plugin
        @bus = plugin["."]
        @project_slot = @bus['/project']
        @project_slot.manager = self
        @properties = @plugin.properties
        
        # Load all previously opened projects.
        @bus['/system/state/all_plugins_loaded'].subscribe do |event, slot|
          if slot.data == true
            @bus['log/info'] << "Opening project files"
            
            if @properties['active'].nil?
              @bus['log/info'] << "No active projects found."
              @properties['active'] = []
            end
            open_default_project
            
            unfound_prj_files = []
            @properties['active'].each do |prj|
              if File.exists?(prj)
                open_project(prj)
              else
                unfound_prj_files << prj
              end
            end
            unfound_prj_files.each do |p| @properties['active'].delete(p) end
            
          end
        end
      end
      
      def new_project
        NewProjectDialog.new(@plugin).show(PLACEMENT_SCREEN)
      end
      
      # Open the given project-file. Creates a new project-slot if necessary.
      # Also adds the project to the list of opened projects.
      def open_project(frproj_file, name=nil)
        unless File.absolute_path?(frproj_file)
          frproj_file = File.join(@plugin.plugin_configuration.base_user_path, frproj_file)
        end
        
        unless @properties['active'].include?(frproj_file)
          @properties["active"] << frproj_file
          @properties.save
        end
        slot_name = nil
        unless opened?(frproj_file)
          slot_idx = last_project_index
          slot_name = "/project/active/#{slot_idx}"
          p = Project.new( @plugin[slot_name], frproj_file, name)
          name = p.name
        end
        slot_name = find_project_slot_name(frproj_file) unless slot_name
        
        # Add the project to project-explorer
        @bus['/system/ui/commands'].manager.command(
            "App/Project/Explorer/Add_Project").invoke(@bus["#{slot_name}"])
        slot_name
      end
      
      # Close all projects, only used on exit. Opened project will be reopened next
      # time FR starts.
      def close_all_projects
        @plugin['/project/active/'].each_slot do |slot|
          break false unless slot.manager.close
        end
      end
      
      # Removes the project from the list of opened projects
      def close_project(slot)
        prj = slot.manager
        if prj.close
          @properties["active"].delete(prj.properties_path)
          @properties.save
          slot.prune
        end
        #@plugin['/project'].dump
      end
      
      # Check if the project has already been openened
      def opened?(frproj_file)
        if @project_slot.has_child?('active')
          @project_slot['active'].each_slot do |prj|
            return true if prj.data == frproj_file
          end
        end
        false
      end
      
      # Every editpane is 'managed' by a project
      # This method returns the project-instance associated with
      # the given editpane-slot
      def get_project_for_editpane(ep_slot)
        project_slot = nil
        @plugin['/project/active/'].each_slot do |slot|
          slot.manager.ep_slots.each do |e|
            if(e.data == ep_slot.data)
              project_slot = slot
              break
            end
          end
          break if project_slot
        end
        
        if project_slot.nil?
          return @plugin['/project/active/default']
        else
          return project_slot
        end
        
      end
      
      def last_project_index
        @@last_index += 1
      end
      
      private
      
      def open_default_project
        unless opened?('default_project.frproj')
          open_project('default_project.frproj', "Default Project")
        end
      end
      
      def find_project_slot_name(prj_file)
        @project_slot['active'].each_slot do |prj|
          return prj.path if prj.data == prj_file
        end
        raise "project not found, shouldn't happen"
      end
    end
  end
end
