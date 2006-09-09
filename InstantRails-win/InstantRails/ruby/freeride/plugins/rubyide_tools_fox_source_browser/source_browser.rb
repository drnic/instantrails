# Purpose: Setup and initialize the dock bar gui interfaces
#
# $Id: source_browser.rb,v 1.6 2005/11/15 03:29:41 jonathanm Exp $
#
# Authors:  NISHIO Mizuho
# Contributors: Rich Kilmer
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 NISHIO Mizuho. All rights reserved.
#

require 'rubyide_tools_fox_source_browser/source_tree'
require 'thread'

module FreeRIDE
  module FoxRenderer
    
    class SourceBrowser
      include Fox
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        # Handle icons
        plugin['/system/ui/icons/SourceBrowser'].subscribe do |event, slot|
          if event == :notify_slot_add
            app = plugin['/system/ui/fox/FXApp'].data
            path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
            if FileTest.exist?(path)
              slot.data = Fox::FXPNGIcon.new(app, File.open(path, "rb").read)
              slot.data.create
            end
          end
        end
        
        # Add command
        @@browser = SourceBrowser.new(plugin)
        plugin["/system/ui/commands"].manager.add("App/View/SourceBrowser","Source Browser","View Source Navigation Tree") do |cmd_slot|
          @@browser.toggle
        end
        plugin["/system/ui/commands"].manager.command("App/View/SourceBrowser").icon = "/system/ui/icons/SourceBrowser/ruby_file"
        plugin["/system/ui/keys"].manager.bind("App/View/SourceBrowser", :F7)
        
        plugin["/system/ui/current/ToolBar"].manager.add_command("View", "App/View/SourceBrowser")
        
        # Insert the inspector in the View menu
        viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
        viewmenu.add_command("App/View/SourceBrowser")
        viewmenu.uncheck("App/View/SourceBrowser")
                
        plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if slot.data == true
            if plugin.properties["Open"]
              @@browser.toggle
            end
          end
        end

        # run the thread polling for file update that needs refresh
        Thread.new(plugin, @@browser) do |plugin, browser|
          file_sizes = Hash.new
          while true
            sleep 5
            if plugin['/system/ui/current/EditPane'].is_link_slot? && browser.visible? 
              length = plugin['/system/ui/current/EditPane/actions/get_text_length'].invoke
              filename = plugin['/system/ui/current/EditPane'].data

              if (file_sizes[filename] != length)
                browser.update_tree
                file_sizes[filename] = length
              end
            end
          end
        end
        
        plugin['log/info'] << "SourceBrowser plugin started"
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def self.stop(plugin)
        @@browser.stop
      end

      
      def initialize(plugin)
        @plugin = plugin
	      @busy_updating = Mutex.new
        @cmd_mgr = plugin['/system/ui/commands'].manager
        @dockpane_slot = plugin['/system/ui/components/DockPane'].manager.add("Source View")
        main_window = @plugin["/system/ui/fox/FXMainWindow"].data
        frm = Fox::FXHorizontalFrame.new(main_window, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,0,0,0,0,0,0,0,0)      
        @tree = SourceTree.new(frm, plugin)
        @viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
        frm.hSpacing = 0
        frm.vSpacing = 0
        frm.hide
        frm.create
        @dockpane_slot.data = frm
        def @tree.on_selected(node)
          line_no = self.get_node_data(node)
          editpane = @plugin["/system/ui/current/EditPane"].manager
          if editpane
            editpane.set_cursor_line(line_no)
          end
        end

        # When the first editpane is created update the source browser
        # When the last editpane is closed clear the source browser
        @plugin['/system/ui/current'].subscribe do |event, slot|
          if slot.name=="EditPane"
            if event == :notify_slot_link
              update_tree
            elsif event==:notify_slot_unlink
              @tree.clear_nodes
            end
          end
        end

        # When the dockpane informs us that it is opened or closed
        # adjust the menu item and properties accordingly 
        @dockpane_slot["status"].subscribe do |event, slot|
          if event == :notify_data_set
            if @dockpane_slot["status"].data == 'opened'
              @checked = true
              @viewmenu.check("App/View/SourceBrowser")
              @plugin.properties["Open"] = true
            elsif @dockpane_slot["status"].data == 'closed'
              @viewmenu.uncheck("App/View/SourceBrowser")
              @checked = false
              @plugin.properties["Open"] = false
            end
          end
        end

        # Dock it now that everything is ready
        @dockpane_slot.manager.dock('west')

      end

      def stop
	@busy_updating.synchronize { 
	  # wait for update to complete before stopping
	  # or it might result in a core dump
	}
      end
      
      def visible?
        @dockpane_slot.manager.current?
      end

      def toggle
        # hide it if visible, show it if invisible
        @checked ? hide : show
      end
      
      def show
        @dockpane_slot.manager.show
        update_tree
      end

      def hide
        @dockpane_slot.manager.hide
      end

      def update_tree
        @busy_updating.synchronize do
          editpane = @plugin["/system/ui/current/EditPane"].manager
          if editpane
            source = editpane.parse_code
            @tree.clear_nodes
            
            fn = @plugin['/system/ui/current/EditPane'].data
            @tree.add_source(source.top_level_context, nil, fn) if source
            expandTree(@tree)
	          @tree.update
          end
	      end
      end
      
      def expandTree(treeList, item=nil)
        item = treeList unless item
        item.each do |child|
          treeList.expandTree(child)
          expandTree(treeList, child)
        end
      end
      
    end
    
  end
end
