# Purpose: Dialog for creating a new project
#
# $Id: new_project_dialog.rb,v 1.3 2005/12/08 11:29:19 jonathanm Exp $
#
# Authors:  Jonathan Maasland <nochoice @ xs4all.nl>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Jonathan Maasland All rights reserved.
#

begin
  require 'rubygems'
  require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
  require 'fox12'
end

require 'rubyide_project/project'
require 'rubyide_tools_fox_project_explorer/prop_view_helpers'

module FreeRIDE
  module Tools
  
    class NewProjectDialog < Fox::FXDialogBox
      include Fox
      
      def initialize(plugin)
        @plugin = plugin
        @app = @plugin['/system/ui/fox/FXApp'].data
        
        super(@app, "New project", DECOR_ALL, 20,20)
        content_panel = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @renderer = PropertyViewHelpers::ProjectSettingsRenderer.new(content_panel)
        @renderer.init_gui(@plugin)
        
        # Panel for the cancel and ok buttons
        button_panel = FXHorizontalFrame.new(content_panel, LAYOUT_FILL_X)
        cancel_btn = FXButton.new(button_panel, "Cancel", nil, nil, 0, 
              BUTTON_NORMAL, 0, 0, 0, 0, 20, 20)
        cancel_btn.connect(SEL_COMMAND, method(:cancelDialog))
        ok_btn = FXButton.new(button_panel, "  OK  ", nil, nil, 0, 
              BUTTON_NORMAL|LAYOUT_RIGHT, 0,0, 0, 0, 20, 20)
        ok_btn.connect(SEL_COMMAND, method(:finishDialog))
        
        self.connect(SEL_CLOSE, method(:cancelDialog))
        hide
        create
      end
      
      private
      
      def cancelDialog(sender, sel, data)
        self.hide # and destroy?
      end
      
      # Called when the user presses OK
      #
      def finishDialog(sender, sel, data)
        return if !@renderer.validate_project_location
        
        slot_name = create_project
        return unless slot_name
        
        @plugin[slot_name].data = @renderer.get_project_filename
        Project.new(@plugin[slot_name], @renderer.get_project_filename)
        @plugin['/project'].manager.open_project(@renderer.get_project_filename)
        cancelDialog(nil,nil,nil)
      end
      
      
      # Creates a new slot under /project/active for this project.
      # Creates and sets the properties file as well for the project.
      def create_project
      
        if @renderer.create_basedir?
          begin
            @renderer.create_basedir
          rescue
            @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin,
              "Error", "Error creating the basedirectory. #{$!.message}")
            return nil
          end
        end
        
        slot_name = "/project/active/" + @plugin['/project'].manager.last_project_index.to_s
        props = FreeBASE::Properties.new("rubyide_project-project", "1.0", 
              @plugin[slot_name + "/properties"], @renderer.get_project_filename)
        props.auto_save = false
        
        props['name'] = @renderer.project_name
        props['basedirectory'] = @renderer.basedir
        props['default_script'] = @renderer.default_script
        
        props['source_directories'] = @renderer.source_dirs
        props['required_directories'] = @renderer.required_dirs
        
        props['working_dir'] = @renderer.working_dir
        props['cmd_line_options'] = @renderer.command_line_options
        props['run_in_terminal'] = @renderer.run_in_terminal?
        props['save_before_running'] = @renderer.save_before_running?
        
        props.auto_save = true
        props.save
        
        return slot_name
      end
      
    end
  end
end