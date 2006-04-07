# Purpose: Setup and initialize the Ruby-interpreters configuration pane
#
# Authors:  Jonathan Maasland < nochoice AT xs4all.nl >
# Partially based on: fox_debugger_configurator.rb
#  by Laurent Julliard and Richard Kilmer
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Jonathan Maasland. All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

module FreeRIDE
  module FoxRenderer

    module DebuggerRenderFox

      class RubyConfiguratorRenderer
        include Fox
        
        def initialize(plugin)
          @plugin = plugin
          @dbg_plugin = plugin['/plugins/rubyide_tools_debugger'].manager
          @main = plugin['/system/ui/fox/FXMainWindow'].data
          
          # Construct the ruby-interpreters configuration subpanel 
          # Parent it to the main window
          rubypanel = FXHorizontalFrame.new(@main, FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          group = FXGroupBox.new(rubypanel, "Configured Ruby Interpreters",
                         GROUPBOX_TITLE_LEFT|FRAME_RIDGE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          group_frame = FXHorizontalFrame.new(group, FRAME_NONE|LAYOUT_FILL_Y|LAYOUT_FILL_X)
          
          # Create the left part of the panel
          list_frame = FXVerticalFrame.new(group_frame, FRAME_NONE|LAYOUT_FILL_Y)
          @irv_list = FXList.new(list_frame, nil, 0,
                          LAYOUT_FILL_X|LAYOUT_FILL_Y|LIST_NORMAL) do |lst|
            lst.connect(SEL_CHANGED, method(:onCmdChangeSel))
          end
          button_frame = FXHorizontalFrame.new(list_frame, LAYOUT_FILL_X)
          FXButton.new(button_frame, "Add") do |button|
            button.connect(SEL_COMMAND, method(:onCmdAdd))
          end
          @remove_btn = FXButton.new(button_frame, "Remove") do |button|
            button.connect(SEL_COMMAND, method(:onCmdRemove))
          end
          
          # Create the interpreter settings-view (right part)
          group_frame2 = FXVerticalFrame.new(group_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          FXLabel.new(group_frame2, "Name:")
          @rb_name = FXTextField.new(group_frame2, 15, nil, 0,
                  LAYOUT_FILL_X|TEXTFIELD_NORMAL)
          @rb_name.connect(SEL_COMMAND, method(:name_changed))
      
          FXLabel.new(group_frame2, "Version:")
          @rb_ver = FXTextField.new(group_frame2, 15, nil, 0,
                  LAYOUT_FILL_X|TEXTFIELD_NORMAL)
          @rb_ver.disable
          
          FXLabel.new(group_frame2, "Executable:")
          tmp_panel = FXHorizontalFrame.new(group_frame2, LAYOUT_FILL_X)
          @rb_exec = FXTextField.new(tmp_panel, 15, nil, 0,
                  LAYOUT_FILL_X|TEXTFIELD_NORMAL)
          @rb_exec.connect(SEL_COMMAND, method(:tf_changed))
          FXButton.new(tmp_panel, "...", nil, nil, 0, BUTTON_NORMAL|LAYOUT_RIGHT) do |button|
            button.connect(SEL_COMMAND, method(:onCmdBrowseRuby))
          end
          
          FXLabel.new(group_frame2, "Path:")
          tmp_panel = FXHorizontalFrame.new(group_frame2, LAYOUT_FILL_X)
          @rb_path = FXTextField.new(tmp_panel, 25, nil, 0,
                  LAYOUT_FILL_X|TEXTFIELD_NORMAL)
          @rb_path.connect(SEL_COMMAND, method(:tf_changed))
          FXButton.new(tmp_panel, "...", nil, nil, 0, BUTTON_NORMAL|LAYOUT_RIGHT) do |button|
            button.connect(SEL_COMMAND, method(:onCmdBrowsePath))
          end
          
          rubypanel.create
          rubypanel.hide
          
          pcfg = plugin['configurator/Debugger']
          pcfg['Ruby'].attr_icon = nil
          pcfg['Ruby'].attr_label = 'Installed Ruby interpreters'
          pcfg['Ruby'].attr_description = 'Add or remove installed Ruby interpreters'
          pcfg['Ruby'].attr_frame = rubypanel
          
          # Ensure that at least one ruby interpreter is present or try to create it
          plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
            if slot.data == true
              interpreters = @dbg_plugin.properties["interpreters"]
              unless interpreters and interpreters.size > 0
                # Try and setup the default ruby interpreter
                ruby_command = get_default_ruby_path
                if ruby_command
                  @rb_path.text, @rb_exec.text = extract_path_and_exec(ruby_command)
                  @rb_name.text = "default"
                  s = { "default" => get_settings }
                  @dbg_plugin.properties["interpreters"] = s
                  @dbg_plugin.properties["path_to_ruby"] = s["default"]["command"]
                else
                  @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin,
                          "Where is Ruby?", "I can't find the Ruby interpreter. " + 
                          "Please configure the path to ruby in the Debugger/Run preference box")
                end
              end
            end
          end
          
        end
        
        # Called by the DebuggerConfigurator to load the settings in the gui
        # The default interpreter is unique in that it always exists and it's
        # name is always 'default'
        #
        # All settings are stored in a hash
        # The given name for the interpreter is the key, it's value is
        # a hash containing the settings
        def load_properties
          @irv_list.clearItems
          interpreters = @dbg_plugin.properties['interpreters']
          unless interpreters
            interpreters = { 'default' => get_new_settings }
            interpreters['default']['name'] = 'default'
          end
          interpreters.each do |key, value|
            idx = @irv_list.appendItem(key)
            @irv_list.setItemData(idx, value)
          end
          @irv_list.selectItem(0)
          # Adding true to the above statement should fire a SEL_CHANGED event
          # for the list, it does not however :(
          onCmdChangeSel(nil, nil, 0)
          @modified = false
          
          @plugin.log_info << "Loaded Debugger/Ruby properties"
        end
        
        ## 
        # Called by DebuggerConfigurator to save the settings
        def save_properties
          # Save all changes in the list
          @irv_list.setItemData(@selected_idx, get_settings)
          @irv_list.setItemText(@selected_idx, @rb_name.text)
          
          rubies = Hash.new
          @irv_list.numItems.times do |idx|
            rubies[ @irv_list.getItemText(idx) ] = @irv_list.getItemData(idx)
          end
          @dbg_plugin.properties["interpreters"] = rubies
          
          # Check if the default_interpreter still exists
          unless rubies[@dbg_plugin.properties["default_interpreter"]]
            @dbg_plugin.properties["default_interpreter"] = @irv_list.getItemText(0)
          end
          # Always set path_to_ruby
          @dbg_plugin.properties["path_to_ruby"] = rubies[@dbg_plugin.properties["default_interpreter"]]["command"]
          
          @modified = false          
          @plugin.log_info << "Saved Debugger/Ruby properties"
        end
        
        # Called by DebuggerConfigurator
        def modified?
          return @modified
        end
        
        private
        
        # Searches PATH for a file named ruby and returns the path to it, or nil
        def get_default_ruby_path
          if PLATFORM =~ /(mswin32|mingw32)/
            path_delim = ";"
            ruby_names = [ "ruby.bat", "ruby.exe" ]
          else
            path_delim = ":"
            ruby_names = [ "ruby" ]
          end
          
          ENV['PATH'].split(path_delim).each do |path_entry|
            ruby_names.each do |name|
              full_path = File.join(path_entry, name)
              if File.exists?(full_path)
                @plugin.log_debug << "Using #{full_path} as the default ruby interpreter"
                return full_path 
              end
            end
          end
          @plugin.log_info << "Unable to find a default ruby interpreter"
          @no_default_ruby_found = true
          return nil
        end
        
        # Attempt to run a ruby command using the currently provided settings.
        # If no executable name is provided this method will try 'ruby' as a default
        # 
        # If succesful the ruby's version output is returned. 
        # If an error occurred, false is returned
        def try_settings
          if @rb_path.text == '' and @rb_exec.text == ''
            @rb_ver.text = ''
            return false 
          end
            
          if @rb_path.text == ''
            ruby_exec = @rb_exec.text
            # Try to find an executable file named ruby_exec in the PATH (so we can set it's path)
            path_delim = (PLATFORM =~ /(mswin32|mingw32)/)? ";" : ":"
            ENV['PATH'].split(path_delim).each do |path_entry|
              full_path = File.join(path_entry, ruby_exec)
              if File.exists?(full_path) and File.executable?(full_path)
                @rb_path.text = path_entry
                ruby_exec = full_path
                break
              end
            end
          else
            ruby_exec = File.join(@rb_path.text, @rb_exec.text)
            if(!(File.exists?(ruby_exec) and File.executable?(ruby_exec)))
              @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin,
                    "Error", "Could not find or execute #{ruby_exec}")
              @rb_ver.text = ''
              return false
            end
          end
          
          cmd = "#{ruby_exec} -v -e \"puts 'helloWorld'\""
          begin
            output = `#{cmd}`
          rescue
            @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin,
                  "Error", "Error executing #{ruby_exec}")
            @rb_ver.text = ''
            return false
          end
          
          ver, line = output.split("\n")
          if((ver and line) and (ver =~ /ruby/) and (line == "helloWorld"))
            @rb_ver.text = ver
            return true
          else
            error_msg = "Error executing #{ruby_exec}"
            error_msg += "Command output was\n#{output}" if output != ''
            @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin,
                  "Error", error_msg)
            @rb_ver.text = ''
            return false
          end
        end
        
        # Returns a hash containing the current values in the ui
        def get_settings
          rv = { "name" => @rb_name.text,
            "exec" => @rb_exec.text,
            "path" => @rb_path.text, 
            "command" => File.join(@rb_path.text , @rb_exec.text),
            "version" => @rb_ver.text }
          rv["command"] = @rb_exec.text if @rb_path.text == ''
          return rv
        end
        
        # Returns a hash containing the default settings
        def get_new_settings
          rv = { "name" => "unnamed", "path" => "" }
          if @no_default_ruby_found
            rv['exec'] = ''
            rv['command'] = ''
          else
            rv['exec'] = 'ruby'
            rv['command'] = 'ruby'
          end
          return rv
        end
        
        # Method returns an array of two elements
        # The first is the path, the second the name of the executable
        def extract_path_and_exec(full_path)
          dn = File.dirname(full_path)
          fn = full_path[dn.size+1..-1]  # +1 to remove the starting path-separator
          [dn, fn]
        end
        
        def name_changed(sender, sel, ptr)
          if @rb_name.text == ''
            # Find the number to append to the default 'unnamed' name
            # Somewhat buggy, need to expand on this :(
            last_unnamed_nr = 0
            idx = -1
            while( (idx = @irv_list.findItem(
                        'unnamed', idx, SEARCH_FORWARD|SEARCH_PREFIX|SEARCH_NOWRAP)) != -1)
              @irv_list.getItemText(idx) =~ /unnamed([\d]*)/
              if $1 and $1.length > 0
                last_unnamed_nr = $1.to_i if($1.to_i > last_unnamed_nr)
              end
              idx += 1
            end
            @rb_name.text = "unnamed#{last_unnamed_nr+1}"
          else
            check_duplicate_name
          end
          @irv_list.setItemText(@selected_idx, @rb_name.text)
        end
        
        
        def tf_changed(sender, sel, ptr)
          @modified = true
          
          exec_empty = false
          if @rb_exec.text == ''
            exec_empty = true
            @rb_exec.text = 'ruby'
          end
          
          if !try_settings and exec_empty
            @rb_exec.text = ''
          end
        end
        
        
        def onCmdBrowsePath(sender, sel, ptr)
          dlg = FXDirDialog.new(@main, "Select the path to ruby")
          if dlg.execute != 0
            @rb_path.text = dlg.getDirectory
            try_settings
          end
        end
        
        def onCmdBrowseRuby(sender, sel, ptr)
          dlg = FXFileDialog.new(@main, "Select the ruby executable")
          dlg.setPatternList("Files starting with ruby (ruby*)\nAll files (*)")
          dlg.setDirectory(@rb_path.text) if File.exists?(@rb_path.text)
          
          if dlg.execute != 0
            @rb_path.text, @rb_exec.text = extract_path_and_exec(dlg.getFilename)
            @modified = true
            try_settings
          end
        end
        
        def onCmdAdd(sender, sel, ptr)
          new_settings = get_new_settings
          new_idx = @irv_list.appendItem(new_settings['name'])
          @irv_list.setItemData(new_idx, new_settings)
          @irv_list.killSelection
          @irv_list.setCurrentItem(new_idx)
          @remove_btn.enable
          onCmdChangeSel(nil, nil, new_idx)
          
          @modified = true
        end
        
        def onCmdRemove(sender, sel, ptr)
          @irv_list.removeItem(@selected_idx)
          @irv_list.setCurrentItem(0)
          @irv_list.selectItem(0, true)
          # Set @selected_idx to false so onCmdChangeSel doesn't try to save changes
          @selected_idx = false
          onCmdChangeSel(nil, nil, 0)
          
          @modified = true
        end
        
        # Method checks whether the currently provided name is already in use
        # If it is then a suffix is added
        def check_duplicate_name
          found = false
          @irv_list.numItems.times do |idx|
            next if idx == @selected_idx
            if @rb_name.text == @irv_list.getItemText(idx)
              found = true
              break
            end
          end
          
          if found
            cnt = 0
            cnt += 1 while(@irv_list.findItem("#{@rb_name.text + cnt.to_s}") != -1)
            @rb_name.text = @rb_name.text + cnt.to_s
          end
        end
        
        # Called when the list-selection changes
        # ptr is the index of the new selection
        def onCmdChangeSel(sender, sel, ptr)
          # @selected_idx still points to the old selection, so we can use to
          # save the current ui-settings
          check_duplicate_name
          if(@selected_idx) # and @irv_list.numItems-1 >= @selected_idx)
            @irv_list.setItemText(@selected_idx, @rb_name.text)
            @irv_list.setItemData(@selected_idx, get_settings)
          end
          
          if @irv_list.numItems == 1
            @remove_btn.disable
          end
          
          settings = @irv_list.getItemData(ptr)
          @rb_name.text = settings['name']
          @rb_path.text = settings['path']
          @rb_exec.text = settings['exec']
          try_settings
          @selected_idx = ptr
        end
        
      end
    end
  end
end
