# Purpose: A subclass of SourceTree which allows adding directories
#
# $Id: directory_source_tree.rb,v 1.3 2006/02/26 14:25:19 jonathanm Exp $
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
require 'pathname'

require 'rubyide_tools_fox_source_browser/source_tree'

module FreeRIDE
  module FoxRenderer
  
    class DirectorySourceTree < SourceTree
      include Fox
      
      def initialize(parent, plugin, opts = 0)
        super(parent,plugin,opts)
        @plugin = plugin
        @filetypes = []
        
        ftypes = plugin['/plugins/rubyide_tools_fox_file_browser/properties/FileTypes'].data
        ftypes.split(',').each do |ft|
          @filetypes << ft
        end
        plugin["/plugins/rubyide_tools_fox_file_browser/properties/FileTypes"].subscribe do |event,slot|
          if event == :notify_data_set
            @filetypes = []
            slot.data.split(',').each do |ft|
              @filetypes << ft
            end
            # Refresh the tree from the root
          end
        end
      end
      
      # Adds a directory and it's content to this list.
      #
      # directory can be either a String or a Pathname instance. If directory is a String then
      # the full pathname of the directory will be added as the first treeItem, otherwise only
      # the basename of the directory will be used.
      #
      # Each newly created item in the tree has a hash as it's user-data
      # The values stored in the hash are:
      # - 'type': A string representing the type of item
      #   Generated types are: file, directory and rubyscript
      # - 'path': The fully qualified name of the file or directory
      # - 'filename': The last part of the path indicating either filename or directory-name
      # - 'timestamp': The timestamp of the file/directory
      #
      # If the item is aruby-script 'source' will point to the parsed 
      # source-structure (see source_structures.rb).
      # If the item is a file 'size' will be set to the filesize(bytes)
      #
      # append can have the following values:
      # - true:  create the new node as the last child of otherNode
      # - false: create the new node after otherNode
      # - nil:   create the new node before otherNode
      #
      def add_directory(directory, otherNode, append = true)
        item = nil
        begin
          @plugin["/system/ui/fox/FXApp"].data.beginWaitCursor
          path = directory
          path = Pathname.new(directory) unless directory.instance_of?(Pathname)
          
          # Construct the new node
          name = (directory.instance_of?(String))? path.to_s : path.basename.to_s
          icon = get_icon("folder")
          if append.nil?
            item = add_node_before(otherNode, name, icon)
          elsif append == true
            item = add_child_node(otherNode, name, icon)
          else
            item = add_node(otherNode, name, icon)
          end
          set_node_data(item, { "path" => path.to_s, "timestamp" => path.atime,
              "type" => "directory", "filename" => path.basename.to_s } )
          
          # Read the directory contents so they can be sorted later
          dirs, files, rb_files = [], [], []
          path.each_entry do |path_entry| 
            next if path_entry.to_s == "." or path_entry.to_s == ".."
            f = path.join(path_entry)
            if f.directory?
              dirs << f
            elsif f.fnmatch("*.rb")
              rb_files << f
            else
              files << f
            end
          end
          
          dirs.sort.each do |directory|
            add_directory(directory, item) 
          end
          rb_files.sort.each do |rubyscript|
            add_rubyscript(rubyscript, item)
          end
          files.sort.each do |file|
            add_file(file, item)
          end
          
        ensure
          @plugin["/system/ui/fox/FXApp"].data.endWaitCursor
        end
        item
      end
      
      # If the file denoted by path_entry matches one of the FileType extensions
      # then a new child element will be added to this list.
      #
      # path_entry can be either a String or a Pathname
      #
      def add_file(path_entry, parentNode, append = true)
        path_entry = Pathname.new(path_entry) unless path_entry.instance_of?(Pathname)
        
        name = path_entry.basename.to_s
        icon = get_icon("document")
        return unless show?(name)
        
        if append.nil?
          x = add_node_before(parentNode, name, icon)
        elsif append == true
          x = add_child_node(parentNode, name, icon)
        else
          x = add_node(parentNode, name, icon)
        end
        set_node_data(x, { 'path' => path_entry, 'type' => 'file' } )
      end
      
      
      # Parses file and adds the source-tree to the list
      #
      def add_rubyscript(file, parentNode, append = true)
        path = file
        path = Pathname.new(file) if file.instance_of?(String)
        
        parser = @plugin['/system/tools/SourceParser/unbound'].data
        source = nil
        begin
          path.open do |io|
            source = parser.parse(io, path.basename.to_s, path.dirname)
          end
        rescue
          @plugin['log/error'] << $!.message
          @plugin['log/error'] << $!.backtrace.join("\n")
          source = nil
        end
        
        if source
          item = add_source(source.top_level_context, parentNode, path.basename.to_s, nil, append)
          item.data = { "path" => path.to_s, 
            "timestamp" => path.atime,
            "type" => "rubyscript",
            "source" => source, 
            "filesize" => path.size }
        else
          item = add_file(path, parentNode, append)
        end
        item
      end
      
      
      # Check configured visible filetypes to see if file_name should be shown
      def show?(file_name)
        file_name = Pathname.new(file_name) unless file_name.instance_of?(Pathname)
        r = false
        @filetypes.each do |fre|
          if(file_name.fnmatch(fre))
            r = true
            break
          end
        end
        r
      end
      
      
    end
  end
end
