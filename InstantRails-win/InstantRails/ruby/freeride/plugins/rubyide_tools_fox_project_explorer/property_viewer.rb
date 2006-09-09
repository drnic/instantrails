# Purpose: Property-viewer plugin
#
# $Id: property_viewer.rb,v 1.3 2006/02/26 14:25:19 jonathanm Exp $
#
# Authors: Jonathan Maasland <nochoice AT xs4all.nl>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Jonathan Maasland All rights reserved.
#

require 'rubyide_tools_fox_project_explorer/prop_view_helpers'
require 'fileutils'

module FreeRIDE
  module Tools
  
  
class PropertyViewer 
  extend FreeBASE::StandardPlugin
  include Fox
  
  def self.start(plugin)
    @@viewer = PropertyWindow.new(plugin)
    
    plugin["/system/ui/commands"].manager.add("App/Project/Explorer/ViewProperty",
          "View property") do |plugin, item|
      @@viewer.show(item)
    end
  end
  
end

class PropertyWindow
  include Fox
  
  def initialize(plugin)
    @app = plugin["/system/ui/fox/FXApp"].data
    @window = FXMainWindow.new(@app, "Property viewer", nil, nil, DECOR_ALL)
    content_panel = FXVerticalFrame.new(@window, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # Construct a tabbook to hold the viewers
    @tabbook = FXTabBook.new(content_panel, nil, 0, TABBOOK_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    # For every class defined below in the module PropertyViewTypes we create a new instance.
    # @viewer_map maps all viewer ItemTypes to an array of three elements.
    # the first value is the viewer, the second is the corresponding tab-item.
    # the third is the tabindex
    @viewer_map = {}
    tab_idx = 0
    %w{ FileView DirectoryView RubyView ProjectView }.each do |vt|
      klass = PropertyViewTypes.const_get(vt)
      type = klass.const_get("ItemType")
      tabitem = FXTabItem.new(@tabbook, type.to_s.capitalize)
      parentframe = FXHorizontalFrame.new(@tabbook, 
            LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, 0, 0, 0, 0, 10, 20, 10, 20)
      @viewer_map[type] = [ klass.new(parentframe), tabitem, tab_idx ]
      tab_idx += 1
    end
    
    # Construct and connect the OK and Cancel buttons
    button_panel = FXHorizontalFrame.new(content_panel, LAYOUT_FILL_X)
    cmd_ok = FXButton.new(button_panel, "  Ok  ", nil, nil, 0, 
          BUTTON_NORMAL|LAYOUT_RIGHT, 0, 0, 0, 0, 20, 20)
    cmd_ok.connect(SEL_COMMAND, method(:on_ok))
    cmd_cancel = FXButton.new(button_panel, "Cancel", nil, nil, 0, 
          BUTTON_NORMAL|LAYOUT_RIGHT, 0, 0, 0, 0, 20, 20)
    cmd_cancel.connect(SEL_COMMAND, method(:on_cancel))
    @window.connect(SEL_CLOSE, method(:on_cancel))
    @window.hide
    @created = false
  end
  
  
  def on_cancel(sender,sel,item)
    @changes = false
    @window.hide
  end
  
  def on_ok(sender, sel, item)
    if @current_viewer.apply_changes
      if @current_item.data["type"] == "rubyscript" and !(@viewer_map[:file][0].apply_changes)
        @changes = false
      else
        @changes = true
      end
    end
    @window.hide
  end
  
  
  def show(item)
    unless @created
      @window.create
      @created = true
    end
    
    item_type = item.data["type"].intern
    @viewer_map.each do |viewer_type, arr|
      viewer,tabitem,idx = arr
      if viewer_type == item_type
        @current_viewer = viewer
        viewer.update(item)
        tabitem.show
        @tabbook.setCurrent(idx)
      else
        tabitem.hide
      end
    end
    if item_type == :rubyscript  # Show the File tab for Rubyfiles
      viewer,tab,idx = @viewer_map[:file]
      viewer.update(item) 
      tab.show
      #@tabbook.setCurrent(idx)
    end
    @current_item = item
    @changes = false
    height = (RUBY_PLATFORM =~ /win/)? 500 : 600
    @window.resize(400,height)
    @window.show(PLACEMENT_SCREEN)
    @app.runModalWhileShown(@window)
    return @changes
  end
end

# Module containing all the different viewer-classes.
#
# Each viewer must define:
#   A constructor accepting a parent-component.
#   An update method accepting an FXTreeItem from a directory_source_tree.
#   As well as a constant ItemType symbol indicating the type of treeItems this
#   viewer is for.
#   An apply_changes method which will be called when the user presses OK.
module PropertyViewTypes
  
  class ViewType
  
    def apply_changes
      true
    end
    
    def self.filesize_to_s(sz)
      sz_kb = sz.to_f / 1024
      sz_mb = sz_kb / 1024
      sz_lbl = "Size: "
      if sz_mb.to_i > 0
        sz_mb.to_s =~ /([\d]*.[\d]{1})/
        sz_lbl += "#{$1} MB"
      elsif sz_kb.to_i > 0
        sz_kb.to_s =~ /([\d]*.[\d]{1})/
        sz_lbl += "#{$1} KB"
      else
        sz_lbl += "#{sz} bytes"
      end
      sz_lbl += "  (#{ViewType.format_number(sz)} bytes)"
    end
    
    
    # Utility method to format n as a string with thousands-separators added
    # If n is not a Fixnum it will be formatted with two decimals
    def self.format_number(n)
      if n.is_a?(Fixnum)
        n.to_s.reverse.scan(/.{1,3}/).join(",").reverse
      else
        sprintf("%3.2f", n)
      end
    end
    
  end
  
  class FileView < ViewType
    ItemType = :file
    
    def initialize(parent)
      cpanel = FXVerticalFrame.new(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y)
      
      fn_panel = FXVerticalFrame.new(cpanel, LAYOUT_FILL_X)
      FXLabel.new(fn_panel, "Filename: ")
      @fn = FXTextField.new(fn_panel, 20, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X)
      @fn.editable = false
      
      sz_panel = FXHorizontalFrame.new(cpanel)
      @sz = FXLabel.new(sz_panel, "")
      
      mod_panel = FXHorizontalFrame.new(cpanel)
      FXLabel.new(mod_panel, "Modified: ", nil, LAYOUT_FILL_X)
      @mod = FXLabel.new(mod_panel, "")
      
      @perm_rend = PropertyViewHelpers::PermissionRenderer.new(cpanel)
    end
    
    def update(item)
      @current_item = item
      fn = item.data["path"]
      file_stat = File.stat(fn)
      
      @fn.text = fn.to_s
      @fn.makePositionVisible(@fn.text.length)
      
      @mod.text = file_stat.mtime.to_s
      @sz.text = ViewType.filesize_to_s(file_stat.size)
      
      @perm_rend.update(item)
    end
    
    def apply_changes
      return @perm_rend.apply_changes
    end
    
  end # class FileView
  
  class DirectoryView < ViewType
    ItemType = :directory
    
    def initialize(parent)
      cpanel = FXVerticalFrame.new(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y)
      
      fn_panel = FXVerticalFrame.new(cpanel, LAYOUT_FILL_X)
      FXLabel.new(fn_panel, "Directory name:")
      @name = FXTextField.new(fn_panel, 20, nil, 0, LAYOUT_FILL_X|TEXTFIELD_NORMAL)
      @name.editable = false
      
      sz_panel = FXHorizontalFrame.new(cpanel, LAYOUT_FILL_X)
      @sz = FXLabel.new(sz_panel, "")
      @num_files = FXLabel.new(FXHorizontalFrame.new(cpanel), "")
      
      @loc = PropertyViewHelpers::LOCRenderer.new(cpanel)
      
      @perm_rend = PropertyViewHelpers::PermissionRenderer.new(cpanel)
    end
    
    def update(item)
      @current_item = item
      
      @name.text = item.data["path"].to_s
      
      @sz.text = "Calculating...."
      @size_thread.exit if @size_thread and @size_thread.alive?
      # Update the size-field in a new thread (could take a long time)
      @size_thread = Thread.new do
        @dirs, @files, @scripts, @lines, @ws, @comments = 0, 0, 0, 0, 0, 0
        @total_size = 0   # Total size in bytes of all contained files
        update_count(item)
        @sz.text = ViewType.filesize_to_s(@total_size)
        @num_files.text = "#{@scripts} rubyscripts, #{@files} files, #{@dirs} subdirectories"
        @loc.update(@lines, @comments, @ws)
      end
      
      @perm_rend.update(item)
    end
    
    def apply_changes
      return @perm_rend.apply_changes
    end
    
    private
    
    def update_count(item)
      item.each do |c|
        #break unless @num_files.shown? # exit thread if the window is no longer shown
        if c.data["type"] == "directory" 
          @dirs += 1
          update_count(c)
        else
          @total_size += File.stat(c.data["path"]).size
          if c.data["type"] == "rubyscript"
            @scripts += 1
            src = c.data["source"].top_level_context
            @lines += src.num_lines
            @ws += src.num_whitespace
            @comments += src.total_num_comments
          else
            @files += 1
          end
        end
      end
      
    end
    
  end
  
  class RubyView < ViewType
    ItemType = :rubyscript
    
    def initialize(parent)
      parent = FXHorizontalFrame.new(parent)
      @loc = PropertyViewHelpers::LOCRenderer.new(parent)
    end
    
    def update(item)
      top = item.data['source'].top_level_context
      total = top.num_lines
      comments = top.total_num_comments
      whitespace = top.num_whitespace
      @loc.update(total,comments,whitespace)
    end
    
  end
  
  class ProjectView < ViewType
    ItemType = :project
    
    def initialize(parent)
      @parent = FXHorizontalFrame.new(parent)
      @pr = PropertyViewHelpers::ProjectSettingsRenderer.new(parent)
    end
    
    def update(item)
      @current_item = item
      @pr.update(item)
    end
    
    def apply_changes
      # get settings from @pr and feed it to @current_item.data["slot"]
      p_props = @current_item.data["slot"].manager.properties
      p_props.auto_save = false
      
      if @pr.create_basedir?
        begin
          @pr.create_basedir
        rescue
          @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin,
            "Error", "Error creating the basedirectory. #{$!.message}")
          return false
        end
      end
      
      p_props['name'] = @pr.project_name
      p_props['basedirectory'] = @pr.basedir
      p_props['default_script'] = @pr.default_script
      
      p_props['source_directories'] = @pr.source_dirs
      p_props['required_directories'] = @pr.required_dirs
      
      p_props['working_dir'] = @pr.working_dir
      p_props['cmd_line_options'] = @pr.command_line_options
      p_props['run_in_terminal'] = @pr.run_in_terminal?
      p_props['save_before_running'] = @pr.save_before_running?
      p_props['interpreter'] = @pr.interpreter
        
      p_props.auto_save = true
      p_props.save
      
      return true
    end
  end
end # of module PropertyViewTypes

end # of module Tools
end # FreeRIDE