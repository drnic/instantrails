# Purpose: Examine and debug the FreeBASE databus
#
# $Id: file_browser.rb,v 1.14 2005/11/18 01:37:09 jonathanm Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
# Contributors: Rich Kilmer <rich@infoether.com>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Rich Kilmer All rights reserved.
# Modified 2005 by Jonathan Maasland <nochoice AT xs4all.nl >
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

module FreeRIDE
  module FoxRenderer
    
    ##
    # This module defines the databus inspector
    #
    class FileBrowser
      include Fox
      extend FreeBASE::StandardPlugin
      
      def FileBrowser.start(plugin)
        # Handle icons
        plugin['/system/ui/icons/FileBrowser'].subscribe do |event, slot|
          if event == :notify_slot_add
            app = plugin['/system/ui/fox/FXApp'].data
            path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
            if FileTest.exist?(path)
              slot.data = FXPNGIcon.new(app, File.open(path, "rb").read)
              slot.data.create
            end
          end
        end
        
        # Add command
        browser = FileBrowser.new(plugin)
        plugin["/system/ui/commands"].manager.add("App/View/FileBrowser","File &List") do |cmd_slot|
          browser.toggle
        end
        plugin["/system/ui/commands"].manager.command("App/View/FileBrowser").icon = "/system/ui/icons/FileBrowser/browse"
        
        plugin["/system/ui/keys"].manager.bind("App/View/FileBrowser", :ctrl, :L)
        
        plugin["/system/ui/current/ToolBar"].manager.add_command("View", "App/View/FileBrowser")
        # Insert the inspector in the Tools menu
        viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
        viewmenu.add_command("App/View/FileBrowser")
        viewmenu.uncheck("App/View/FileBrowser")
        plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if slot.data == true
            if plugin.properties["Open"]
              browser.toggle
            end
          end
        end
        
        plugin['log/info'] << "FileBrowser plugin is running"
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin)
        @viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
        @plugin = plugin
        @cmd_mgr = plugin['/system/ui/commands'].manager
        @dockpane_slot = plugin['/system/ui/components/DockPane'].manager.add("File View")
        main_window = @plugin["/system/ui/fox/FXMainWindow"].data
        dirlist = FXDirList.new(main_window, nil, 0, 
          (TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|FRAME_SUNKEN|FRAME_THICK|
          LAYOUT_FILL_X|LAYOUT_FILL_Y|DIRLIST_SHOWFILES), 0, 0, 0, 0)
        
        filetypes_slot = @plugin["properties/FileTypes"]
        filetypes_slot.subscribe do |event,slot|
          if event == :notify_data_set
            dirlist.setPattern(slot.data)
          end
        end
        filetypes_slot.data = "*.rb,*.rbw,*.xml,*.rhtml" unless filetypes_slot.data
        dirlist.setPattern(filetypes_slot.data)
        
        dirlist.connect(SEL_DOUBLECLICKED) { |sender, sel, item|
          if dirlist.isItemFile(item)
            pathname = dirlist.getItemPathname(item)
            plugin.properties["LastFile"] = pathname
            @plugin['/project/active/default'].manager.open_file(pathname)
            #@cmd_mgr.command("App/File/Load").invoke(pathname)
            # Add the file to defaultProject openFiles
          else
            dirlist.expandTree(item, !item.expanded?)
          end
        }
        dirlist.hide
        dirlist.create
        lastFile = plugin.properties["LastFile"]
        if lastFile && lastFile!=""
          dirlist.currentFile = lastFile
        else
          dirlist.directory = Dir.pwd
        end
        
        @dockpane_slot.data = dirlist

        # When the dockpane informs us that it is opened or closed
        # adjust the menu item and properties accordingly 
        @dockpane_slot["status"].subscribe do |event, slot|
          if event == :notify_data_set
            if @dockpane_slot["status"].data == 'opened'
              @checked = true
              @viewmenu.check("App/View/FileBrowser")
              @plugin.properties["Open"] = true
            elsif @dockpane_slot["status"].data == 'closed'
              @viewmenu.uncheck("App/View/FileBrowser")
              @checked = false
              @plugin.properties["Open"] = false
            end
          end
        end

        # Show it now that everything is ready
        @dockpane_slot.manager.dock('west')

      end

      def toggle
        # hide it if visible, show it if invisible
        @checked ? hide : show
      end
      
      def show
        @dockpane_slot.manager.show
      end

      def hide
        @dockpane_slot.manager.hide
      end
      
    end
    
  end
end
