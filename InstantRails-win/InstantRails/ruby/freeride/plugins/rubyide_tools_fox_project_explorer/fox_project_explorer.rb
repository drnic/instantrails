# Purpose: Setup and initialize the project-explorer
#
# $Id: fox_project_explorer.rb,v 1.6 2006/02/26 14:25:19 jonathanm Exp $
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

require 'rubyide_tools_fox_source_browser/directory_source_tree'
require 'rubyide_tools_fox_project_explorer/property_viewer'

require 'pathname'

module FreeRIDE
  module Tools
  
    class FoxProjectExplorer
      extend FreeBASE::StandardPlugin

      include Fox
      
      def self.start(plugin)
        @@plugin = plugin
        @@tree = ProjectExplorerRenderer.new(plugin)
        
        dock_explorer_tree
        reopen_explorer
        add_explorer_commands
        PropertyViewer.start(plugin)
        
        plugin.log_info << "ProjectExplorer is running"
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def self.dock_explorer_tree
        # Dock the renderer in the west panel
        @@dockpane_slot = @@plugin['/system/ui/components/DockPane'].manager.add("Project Explorer")
        @@dockpane_slot.data = @@tree
        @@dockpane_slot.manager.dock('west')
        
        # When the dockpane informs us that it is opened or closed
        # adjust the menu item and properties accordingly 
        @@checked = false
        viewmenu = @@plugin["/system/ui/components/MenuPane/View_menu"].manager
        @@dockpane_slot["status"].subscribe do |event, slot|
          if event == :notify_data_set
            if @@dockpane_slot["status"].data == 'opened'
              @@checked = true
              viewmenu.check("App/View/ProjectExplorer")
              @@plugin.properties["Open"] = true
            elsif @@dockpane_slot["status"].data == 'closed'
              viewmenu.uncheck("App/View/ProjectExplorer")
              @@checked = false
              @@plugin.properties["Open"] = false
            end
          end
        end
      end
      
      # Reopen the explorer if necessary
      def self.reopen_explorer
        @@plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if slot.data == true
            if @@plugin.properties["Open"]
              toggle_explorer
            end
            @@plugin.log_info << "ProjectExplorer started succesfully"
          end
        end
      end
      
      def self.add_explorer_commands
        @@plugin["/system/ui/commands"].manager.add("App/Project/Explorer/Add_Project", 
              "Add project to explorer") do |cmd_slot, project_slot|
          @@tree.add_opened_project(project_slot)
          move_to_front        
        end
        
        @@plugin["/system/ui/commands"].manager.add("App/View/ProjectExplorer",
                "Project Explorer","View Project Explorer") do |cmd_slot|
          toggle_explorer
        end
        @@plugin["/system/ui/keys"].manager.bind("App/View/ProjectExplorer", :F8)
        viewmenu = @@plugin["/system/ui/components/MenuPane/View_menu"].manager
        viewmenu.add_command("App/View/ProjectExplorer")
        viewmenu.uncheck("App/View/ProjectExplorer")
      end
      
      def self.toggle_explorer
        if @@checked
          @@dockpane_slot.manager.hide
          @@checked = false
        else
          move_to_front
          @@checked = true
        end
      end
      
      def self.move_to_front
        @@dockpane_slot.manager.show
      end

      
      class ProjectExplorerRenderer < Fox::FXVerticalFrame
        
        def initialize(plugin)
          @@instance = self
          
          @plugin = plugin
          @project_manager = plugin['/project'].manager
          
          main = @plugin['/system/ui/fox/FXMainWindow'].data
          super(main, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @project_tree = FreeRIDE::FoxRenderer::DirectorySourceTree.new(self, @plugin)
          
          init_menu_enable_map
          create_popupmenu
          
          @active_root = @project_tree.addItemLast(nil, "Active projects")
          @project_tree.expand(@active_root)
          
          @opened_projects = {}  # k: the project-file path, v: the project treeItem
          
          @project_tree.connect(SEL_DOUBLECLICKED, method(:tree_doubleclick))
          @project_tree.connect(SEL_RIGHTBUTTONRELEASE, method(:show_popup_menu))
          
          hide
          create
        end
        
        def self.instance
          @@instance
        end
        
        def tree_doubleclick(sender,sel,item)
          if item_rubyscript?(item) or item_file?(item)
            open_file(item)
          elsif item.data.is_a?(Fixnum) # Source-structure
            pos = item.data
            item = item.parent while (!item_rubyscript?(item))
            ep_slot = open_file(item)
            ep_slot.manager.set_cursor_line(pos)
          else
            @project_tree.expandTree(item, !item.expanded?)
          end
        end
        
        def item_file?(item)
          item.data.is_a?(Hash) and item.data["type"] == 'file'
        end
        
        def item_rubyscript?(item)
          item.data.is_a?(Hash) and item.data["type"] == 'rubyscript'
        end
        
        def item_directory?(item)
          item.data.is_a?(Hash) and item.data["type"] == 'directory'
        end
        
        def item_project_root?(item)
          #@opened_projects.value?(item)
          item.data.is_a?(Hash) and item.data["type"] == 'project'
        end
        
        # Returns the project root-item of the currently selected item in the treelist
        # This method is only invoked through a menu-action.
        # Since no parent of a project-item in the tree can be selected, a project-item
        # is always returned
        def selected_project_item
          ci = @project_tree.currentItem
          ci = @project_tree.cursorItem if ci.nil? || ci == @active_root
          
          ci = ci.parent while(!(item_project_root?(ci) || ci.nil?))
          return ci
        end
        
        # Open the file denoted by the FXTreeItem item.
        def open_file(item)
          # Find the project for this file (ie. the node's parent) 
          # and let the project actually open the file.
          @active_root.each do |p|
            if p.parentOf?(item)
              return p.data["slot"].manager.open_file(item.data['path']) 
            end
          end
        end
        
        
        # Add the project at project_slot to the project-explorer
        def add_opened_project(project_slot)
          project = project_slot.manager
          name    = project_slot['properties/name'].data
          basedir = project_slot['properties/basedirectory'].data
          
          return if name == "Default Project" or name.nil?
          
          if @opened_projects[project.properties_path]
            # Explicitly select the project or something like that
            return
          end
          @plugin['log/info'] << "Adding project #{name} to project-explorer"
          
          lbl = name + " (#{basedir})"
          project_root = @project_tree.add_child_node(@active_root, lbl, @project_tree.get_icon("project"))
          project_root.data = { "slot" => project_slot, "type" => "project" }
          @opened_projects[project.properties_path] = project_root
          
          sources  = @project_tree.add_child_node(project_root, "Source directories")
          required = @project_tree.add_child_node(project_root, "Required directories")
          
          # Add the base- source- and required-directories
          
          if project_slot['properties/source_directories'].data
            project_slot['properties/source_directories'].data.each do |src_dir|
              @project_tree.add_directory(src_dir, sources)
            end
          end
          
          if project_slot['properties/required_directories']
            project_slot['properties/required_directories'].data.each do |src_dir|
              @project_tree.add_directory(src_dir, required)
            end
          end
          
          @project_tree.expand(project_root)
          @project_tree.expand(sources)
        end
        
        # Constant array of all type of items in the ProjectExplorer
        ValidTypeSymbols = [ :project_root, :ruby_file, :other_file, :directory,
              :root_directory, :src_root, :req_root, :all ]
        
        def init_menu_enable_map
          @all_menu_commands = []
          @menu_enable_map = {}
          ValidTypeSymbols.each do |sym| @menu_enable_map[sym] = [] end
        end
        
        # Add a new command to the popupmenu.
        # text is the label of the command in the menu
        # meth is the symbol of the method to call when the command is invoked
        # active_on_sym is a list of symbols for which the item should be enabled
        #
        # The following symbols are valid: 
        # * :project_root 
        # * :ruby_file
        # * :other_file
        # * :directory
        # * :root_directory
        # * :src_root
        # * :req_root
        # * :all
        #
        # :root_directory is for directories under either src_root or required_root
        # :all can be used to force the item to always be shown
        def add_menu_command(text, meth = nil, *active_on_sym)
          if text == "SEPARATOR"
            return FXMenuSeparator.new(@popup_menu)
          end
          fxcmd = FXMenuCommand.new(@popup_menu, text)
          fxcmd.connect(SEL_COMMAND, method(meth))
          
          active_on_sym.each do |sym|
            @menu_enable_map[sym] << fxcmd if @menu_enable_map.has_key?(sym)
          end
          @all_menu_commands << fxcmd
          
          fxcmd
        end

        # Return the symbol representing the type of item
        def get_item_type(item)
          if item_rubyscript?(item)
            return :ruby_file
          elsif item.text == "Source directories"
            return :src_root
          elsif item.text == "Required directories"
            return :req_root
          elsif item_project_root?(item)
            return :project_root
          elsif item_directory?(item)
            p_label = item.parent.text
            if p_label == "Source directories" or p_label == "Required directories"
              return :root_directory
            else
              return :directory
            end
          else
            return :other_file
          end
        end
        
        def show_popup_menu(sender, sel, event)
          # Create the menu now because we're sure the explorer has been created
          (@popup_menu.create; @menu_created = true) unless @menu_created
          @popup_menu.hide
          
          # Acquire the item under the mouse pointer or the selected one if none
          item = nil
          if @project_tree.cursorItem
            item = @project_tree.cursorItem
            @project_tree.setCurrentItem(item)
          else
            return
          end
          @project_tree.selectItem(item)
          return if item == @active_root or item == nil or item.data.is_a?(Fixnum)
          # Enable/disable items in the menu depending on the selected item's type
          type = get_item_type(item)
          @all_menu_commands.each do |c| c.disable end
          @menu_enable_map[type].each do |c| c.enable end
          @menu_enable_map[:all].each do |c| c.enable end
          
          @popup_menu.popup(nil, event.root_x, event.root_y)
          
        end
        
        private
        def create_popupmenu
          @popup_menu = FXMenuPane.new(self)
          @menu_created = false
          # Add the commands to the menu
          add_menu_command("Expand subtree", :on_expand, :all)
          add_menu_command("Refresh", :on_refresh, 
                :directory, :root_directory, :ruby_file)
          add_menu_command("SEPARATOR")
          add_menu_command("Add directory", :on_add_dir, :src_root, :req_root)
          add_menu_command("Remove directory", :on_del_dir, :root_directory)
          add_menu_command("SEPARATOR")
          add_menu_command("Set as default script", :on_default_script, :ruby_file)
          add_menu_command("Run file", :on_run_file, :ruby_file)
          add_menu_command("Run project", :on_run_project, :all)
          add_menu_command("Close project", :on_close_project, :all)
          add_menu_command("SEPARATOR")
          add_menu_command("Properties", :on_props, :directory, :root_directory,
                :project_root, :ruby_file, :other_file)
          
        end
        
        
        def on_refresh(sender,sel,item)
          ci = @project_tree.currentItem
          ni = nil
          # Refreshing is easy, just add a copy of the item -after- itself
          # and then remove it
          if(item_rubyscript?(ci))
            ni = @project_tree.add_rubyscript(ci.data["path"], ci, false)
          elsif get_item_type(ci) == :root_directory
            ni = @project_tree.add_directory(ci.data["path"], ci, false)
          else
            ni = @project_tree.add_directory(Pathname.new(ci.data["path"]), ci, false)
          end
          @project_tree.removeItem(ci)
          @project_tree.selectItem(ni)
          @project_tree.currentItem = ni
        end
        
        def on_add_dir(sender,sel,item)
          current = @project_tree.currentItem
          prj_item = selected_project_item
          project = prj_item.data["slot"].manager
          
          d = @plugin['/system/ui/commands/App/Services/DirDialog'].invoke(@plugin, 
              "Browse for a directory", project.properties["basedirectory"], nil)
          return unless d
          
          if get_item_type(current) == :src_root
            project.properties["source_directories"] << d
          else
            project.properties["required_directories"] << d
          end
          project.properties.save
          @project_tree.add_directory(d, @project_tree.currentItem)
        end
        
        def on_close_project(sender,sel,item)
          prj_item = selected_project_item
          project = prj_item.data["slot"].manager
          if project.close
            # Ask the project_manager to remove the project as well
            @plugin['/project'].manager.close_project(prj_item.data["slot"])
            @opened_projects.delete(project.properties_path)
            @project_tree.removeItem(prj_item)
          end
        end
        
        def on_default_script(sender,sel,item)
          current = @project_tree.currentItem
          prj = selected_project_item.data["slot"].manager
          prj.properties["default_script"] = current.data["path"]
        end
        
        def on_del_dir(sender,sel,item)
          c = @project_tree.currentItem
          prj_props = selected_project_item.data["slot"].manager.properties
          if get_item_type(c.parent) == :src_root
            prj_props["source_directories"].delete(c.data["path"])
          else
            prj_props["required_directories"].delete(c.data["path"])
          end
          prj_props.save
          @project_tree.removeItem(c)
          @project_tree.currentItem = nil
        end
        
        def on_run_project(sender,sel,item)
          project_slot = selected_project_item.data["slot"]
          def_script = project_slot["properties/default_script"].data
          if def_script.nil? or def_script == ""
            @plugin['/system/ui/commands/App/Services/MessageBox'].invoke(@plugin, 
                  "Error", "Please select a default script first for this project")
          else
            project_slot.manager.open_file(def_script)
            @plugin["/system/ui/commands/App/Run/RunScript"].invoke(@plugin)
          end
        end
        
        def on_run_file(sender,sel,item)
          current = @project_tree.currentItem
          # easy hack for running a file, simply load it and invoke the run command :)
          project = selected_project_item.data["slot"].manager
          project.open_file(current.data["path"])
          @plugin["/system/ui/commands/App/Run/RunScript"].invoke(@plugin)
        end
        
        def on_props(sender,sel,item)
          c = @project_tree.currentItem
          project_slot = c.data["slot"]
          x = @plugin["/system/ui/commands/App/Project/Explorer/ViewProperty"].invoke(@plugin,c)
          
          if item_project_root?(c) and x # Remove and re-add the source and required dirs
            
            while(true)
              break unless c.first
              @project_tree.removeItem(c.first)
            end

            # Add the base- source- and required-directories
            sources  = @project_tree.add_child_node(c, "Source directories")
            required = @project_tree.add_child_node(c, "Required directories")
            
            project_slot['properties/source_directories'].data.each do |src_dir|
              @project_tree.add_directory(src_dir, sources)
            end
            project_slot['properties/required_directories'].data.each do |src_dir|
              @project_tree.add_directory(src_dir, required)
            end
            @project_tree.expand(sources)
          end
        end
        
        def on_expand(sender,sel,item)
          expand_total(@project_tree.currentItem)
        end
        
        def expand_total(node)
          @project_tree.expand(node)
          node.each do |child| expand_total(child) end
        end
      end
      
    end
    
  end
end
