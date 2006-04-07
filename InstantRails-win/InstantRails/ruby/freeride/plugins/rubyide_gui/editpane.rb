# Purpose: Setup and initialize the core gui interfaces
#
# $Id: editpane.rb,v 1.19 2005/12/08 11:29:19 jonathanm Exp $
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
    # This is the manager class for editpane components.
    #
    class EditPane < Component
      extend FreeBASE::StandardPlugin
      @@new_count = 1
      
      attr_reader :slot
      
      def EditPane.start(plugin)
        base_slot = plugin["/system/ui/components/EditPane"]
        cmd_mgr = plugin["/system/ui/commands"].manager

        cmd_mgr.add("EditPane/GetAllBreakpoints", "Get All Breakpoints") do |cmd_slot|
          result = {}
          plugin['properties/breakpoints'].each_slot do |slot|
            file = slot.data
            lines = slot['lines'].data
            result[file] = lines
          end
          result
        end
        
        cmd_mgr.add("EditPane/ClearAllBreakpoints", "&Clear All Breakpoints") do |cmd_slot|
          plugin.properties.prune('breakpoints')
        end
        
        cmd_mgr.add("EditPane/GetBreakpointsForFile", "Get File Breakpoints") do |cmd_slot, file|
          slot = nil
          plugin['properties/breakpoints'].each_slot do |bp_slot|
            if bp_slot.data == file
              slot = bp_slot
              break
            end
          end
          lines = slot['lines'].data unless slot.nil?
        end
      
        cmd_mgr.add("EditPane/FindFile", "Find EditPane Slot for File") do |cmd_slot, file|
          slot = nil
          plugin['/system/ui/components/EditPane'].each_slot do |ep_slot|
            if ep_slot.data == file
              slot = ep_slot
              break
            end
          end
          slot
        end
      
        ComponentManager.new(plugin, base_slot, EditPane)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      ##
      # The EditPane constructor is invoked when a new edit pane is
      # autovivified through the creation of new slot in the EditPane
      # pool.
      # If you want to create a new pane programatically then
      # use add_pane
      #
      def initialize(plugin, base_slot)
        setup(plugin, base_slot, nil)
        self.whitespace_visible = plugin.properties['settings/whitespace_visible']
        self.eol_visible = plugin.properties['settings/eol_visible']
        self.linenumbers_visible = plugin.properties['settings/linenumbers_visible']
      end
      
      def mark_new
        @base_slot.data = "Untitled#{@@new_count}"
        @@new_count += 1
      end
      
      def new?
        @base_slot.data =~ /^Untitled\d+$/
      end

      ##
      # Loads the contents of the given file into the editpane. Also restore the
      # breakpoints if any from the EditPane properties
      #
      def load_file(filename)
        @base_slot.data = filename
        @actions['load_file'].invoke(filename, breakpoints)
        @plugin.log_debug << "File #{@base_slot.data} loaded in slot #{@base_slot.path}"
      end
      
      ##
      # make the editpane current (generally makes it visible on top - see Renderer)
      #
      def make_current
        @plugin['/system/ui/current'].link("EditPane", @base_slot)
        @actions['make_current'].invoke
        @plugin.log_debug << "Making EditPane #{@base_slot.path} current"
      end
      
      ##
      # close the editpane and see if the file needs to be saved. Return
      # the answer :
      # 'yes' means the file was saved (if needed) and closed
      # 'no' means the file was closed and not saved (even if needed)
      # 'cancel' means the close operation was aborted
      # The close_all flag is here to indicate whether this method is called 
      # when FR is exiting, in which case we don't want to save property files
      # because the list of files to restore is empty !!
      #
      def close(close_all=false)
        if self.modified?
          answer = @cmd_mgr.command("App/Services/YesNoCancelDialog").invoke("Save Changes...", "Save changes to '#{@base_slot.data}'?")
          answer = self.save if answer == 'yes'
          return answer if answer == 'cancel'
        else
          answer = 'yes'
        end
        
        # make another pane in the neighborhood current
        slot = self.neighbor
        if slot == nil
          @plugin["/system/ui/current"].unlink("EditPane")
        else
          slot.manager.make_current
        end
        
        # at that point we can close and delete the editpane slot
        # and the property slot
        @actions['close'].invoke
        @base_slot.prune
        #@plugin["properties/files/#{@base_slot.name}"].prune unless close_all
        #@plugin.properties.save
        return answer
      end
      
      ##
      # save editpane content to filename
      #
      def save
        return if !self.modified?
        if (@base_slot.data =~ /^Untitled(\d*)/)
          return save_as
        end
        @plugin.log_debug << "Saving file #{@base_slot.data}"
        @actions['save'].invoke(@base_slot.data)
      end
      
      ##
      # save editpane in a file which name must be chosen by
      # the user
      #
      def save_as
        file = @base_slot.data
        if (file =~ /^Untitled(\d*)/)
          file = "untitled#{$1}.rb"
	  is_new_file = true
        else
	  is_new_file = false
	end

        answer = 'no'
        while answer!='yes'
          answer, filename = @cmd_mgr.command("App/Services/FileSaveAs").invoke(file,is_new_file)
          return answer if answer == 'cancel'
          if File.exists?(filename)
            answer = @cmd_mgr.command("App/Services/YesNoDialog").invoke("Save File", "'#{filename}' already exists.\nAre you sure you want to overwrite?")
          else
            answer = 'yes'
          end
        end
        @base_slot.data = filename
        @plugin.log_debug << "Saving file #{file} as #{filename}"
        @actions['save'].invoke(@base_slot.data)
        @plugin['/project/active/default'].manager.open_file(filename)
        
        return answer
      end
      
      ##
      # find the editpane just before that one in the list (this is a visual thing
      # so it's the renderer that's going to tell what is the edit pane appearing
      # just before that one
      #
      def neighbor
        list = []
        @base_slot.parent.each_slot do |slot|
          list << slot
        end
        return nil if list.size==0
        i = list.index(@base_slot)
        return nil if i.nil?
        return list[1] if i == 0
        return list[i-1]
      end
      
      ##
      # has the file in the edit pane been modified
      #
      def modified?
        return @actions['modified'].invoke
      end
      
      ##
      # return the file name loaded in the edit pane
      #
      def filename
        @base_slot.data
      end
      
      ##
      # Undo last changes in the edit pane
      #
      def undo
        @actions['undo'].invoke
      end
      
      ##
      # Redo last changes in the edit pane
      #
      def redo
        @actions['redo'].invoke
      end
      
      ##
      # Cuts the editpane's current selection to the system clipboard.
      #
      def cut
        @actions['cut'].invoke
      end
      
      ##
      # Copies the editpane's current selection to the system clipboard.
      #
      def copy
        @actions['copy'].invoke
      end
      
      ##
      # Pastes the current contents of the system clipboard into the editpane.
      #
      def paste
        @actions['paste'].invoke
      end
      
      ##
      # Gets the full text contained in the editpane buffer
      #
      def get_text
        @actions['get_text'].invoke
      end
      
      ##
      # Gets a parse tree of the text in the editpane buffer
      #
      def parse_code
        @actions['parse_code'].invoke(self.get_text)
      end
      
      ##
      # Highlight a given line number for debug
      #
      def show_debugline(line)
        @actions['show_debugline'].invoke(line)
      end

      ##
      # Highlight a given line number for error
      #
      def show_errorline(line)
        @actions['show_errorline'].invoke(line)
      end
      
      ##
      # The line the cursor is on (line at the top is line #1)
      #
      def cursor_line
        @actions['cursor_line'].invoke + 1
      end
      
      ##
      # The line the cursor is on (line at the top is line #1)
      #
      def set_cursor_line(line)
        @actions['set_cursor_line'].invoke(line)
      end
      
      def is_eol_visible?
        @actions['is_eol_visible'].invoke
      end
      
      def eol_visible=(value)
        @actions['eol_visible'].invoke(value)
      end
      
      def is_whitespace_visible?
        @actions['is_whitespace_visible'].invoke
      end
      
      def whitespace_visible=(value)
        @actions['whitespace_visible'].invoke(value)
      end
      
      def are_linenumbers_visible?
        @actions['are_linenumbers_visible'].invoke
      end
      
      def linenumbers_visible=(value)
        @actions['linenumbers_visible'].invoke(value)
      end
      
      def code_completion
        @actions['code_completion'].invoke
      end

      def help_lookup
        @actions['help_lookup'].invoke
      end

      ##
      # Gets the extended object which has a full API for editing.
      # Depending on the editing component being utilized the API
      # for this object will be different.
      #
      def get_ext_object
        @actions['get_ext_object'].invoke
      end
      
      ##
      # Return the list of breakpoints currently active in this file
      # by their line number 
      #
      # Return:: Array of line numbers
      #
      def breakpoints
        slot = nil
        file = self.filename
        @plugin['properties/breakpoints'].each_slot do |bp_slot|
          if bp_slot.data == file
            slot = bp_slot
            break
          end
        end
        return unless slot
        lines = slot['lines'].data
        return lines ? lines : nil
      end
      
      ##
      # Add a breakpoint line number to the list of active breakpoints
      # and  queue the event in the breakpoints queue (the debugger session
      # if any subscribes to this queue)
      # 
      def add_breakpoint(line)
        slot = nil
        highest = 0
        file = self.filename
        @plugin['properties/breakpoints'].each_slot do |bp_slot|
          if bp_slot.data == file
            slot = bp_slot
            break
          end
          val = bp_slot.name.to_i
          highest = val if val > highest
        end
        unless slot
          slot = @plugin["properties/breakpoints/#{highest+1}"]
          slot.data = file
        end
        lines = slot['lines'].data
        lines = [] unless lines
        lines << line
        slot['lines'].data = lines

        # send the event to the brk point queue
        @base_slot['breakpoints'].queue.join(['add',line])
      end
      
      ##
      # Delete a breakpoint on the given line number
      #
      def delete_breakpoint(line)
        slot = nil
	file = self.filename
        @plugin['properties/breakpoints'].each_slot do |bp_slot|
          if bp_slot.data == file
            slot = bp_slot
            break
          end
        end
        return unless slot
        lines = slot['lines'].data
        return unless lines
        lines.delete(line)
        if lines.size==0
          slot.prune
          @plugin.properties.save
        else
          slot['lines'].data = lines
        end
     
        # send the event to the brk point queue
        @base_slot['breakpoints'].queue.join(['del',line])
      end

   end

  end
end
