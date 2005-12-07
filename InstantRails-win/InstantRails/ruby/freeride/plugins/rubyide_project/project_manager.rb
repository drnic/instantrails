# Purpose: Manages projects in FreeRIDE
#
# $Id: project_manager.rb,v 1.1 2003/06/24 05:05:38 richkilmer Exp $
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

require 'rubyide_project/project'

module FreeRIDE
  module Tools
    class ProjectManager
      extend FreeBASE::StandardPlugin
      def self.start(plugin)
        ProjectManager.new(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin)
        @plugin = plugin
        @project_slot = @plugin['/project']
        @project_slot.manager = self
        if @plugin.properties['active_project']
          open_project(@plugin.properties['active_project'])
        else
          open_default_project
        end
      end
      
      def open_default_project
        open_project('default_project.frproj', "Default Project")
      end
      
      def open_project(frproj_file, name=nil)
        if @project_slot.has_child?('current')
          return if @project_slot['current'].data == frproj_file
          @project_slot['current'].manager.close
        end
        Project.new(@plugin, frproj_file, name)
        @plugin.properties['active_project'] = frproj_file unless @plugin.properties['active_project']==frproj_file
      end
      
    end
  end
end
