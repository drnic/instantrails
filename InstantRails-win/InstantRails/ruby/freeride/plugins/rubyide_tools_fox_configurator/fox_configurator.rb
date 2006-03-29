# Purpose: Setup and initialize the core gui interfaces of the editpane
#
# $Id: fox_configurator.rb,v 1.9 2005/10/20 14:46:08 jonathanm Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
#      
# Contributors: 
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2004 Laurent Julliard. All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end
require 'fox12/responder'

module FreeRIDE
  module FoxRenderer
    
    include Fox

    ##
    # This is the module that renders ediutpanes using
    # FXScintilla.
    #
    class Configurator
      include Fox
      ICON_PATH = "/system/ui/icons/Configurator"
      
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        config_frame_slot = plugin["/system/ui/fox/configurator"]
        
        component_slot = plugin["/system/ui/components/Configurator"]

        # Subscribe to the configurator slot to render any newly created configurator
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end

        # If a new icon is invoked through its slot then autoload the icon
        plugin[ICON_PATH].subscribe do |event, slot|
          if event == :notify_slot_add
            app = slot['/system/ui/fox/FXApp'].data
            path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
            plugin.log_info << "iconpath : #{path}"
            if FileTest.exist?(path)
              slot.data = FXPNGIcon.new(app, File.open(path, "rb").read)
              slot.data.create
            end
          end
        end

        # Now only is this plugin running
        plugin.transition(FreeBASE::RUNNING)
      end
      

      class Renderer
        include Fox
        
        def initialize(plugin, slot)
          @plugin = plugin
          @slot = slot
          @icons = plugin["/system/ui/icons/Configurator"]
          @config_dialog = ConfiguratorDialog.new(plugin)
          setup_actions()
          @plugin.log_info << "Configurator dialog box renderer created"
        end
        
        def setup_actions
          bind_action("start", :start)
          bind_action("show_pane", :show_pane)
        end
        
        def bind_action(name, meth)
          @slot["actions/#{name}"].set_proc method(meth)
        end
        
        ### Commands ###
        
        ##
        # Populate the configurator with all available config pane
        #
        def start()
          @config_dialog.reset()
          @slot['/plugins'].each_slot do |slot|
            if slot.has_child?('configurator')
              slot['configurator'].each_slot { |s| @config_dialog.add_category(s) }
            end
          end
        end

        def show_pane(config_slot)
          @config_dialog.show_pane(config_slot)
        end

      end  # class Renderer
      

      class ConfiguratorDialog < FXDialogBox

        include Fox
        include Responder

        def initialize(plugin)
          @plugin = plugin
          owner = plugin["/system/ui/fox/FXMainWindow"].data

          # Invoke base class initialize function first
          super(owner, "FreeRIDE Configuration...", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE|DECOR_RESIZE)
          self.width = 630
          self.height = 430
          self.padLeft = 0
          self.padRight = 0

          vertical = FXVerticalFrame.new(self,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)

          horizontal = FXSplitter.new(vertical, LAYOUT_FILL_X|LAYOUT_FILL_Y|
                                      SPLITTER_TRACKING|SPLITTER_HORIZONTAL)
          vtf = FXVerticalFrame.new(horizontal,LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK)
          vtf.padLeft = 0; vtf.padRight = 0; vtf.padTop = 0; vtf.padBottom = 0

          @config_tree = FXTreeList.new(vtf, nil, 0,
                                        TREELIST_BROWSESELECT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|
                                        TREELIST_ROOT_BOXES|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	  @config_tree.setNumVisible(10)
          vtf.width = 150

          @config_tree.connect(SEL_COMMAND) do |sender, sel, item|
            getApp.beginWaitCursor
            on_selected(sender,sel,item)
            getApp.endWaitCursor
          end
          
          # Config pane top title zone
          pane = FXVerticalFrame.new(horizontal, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @config_title = FXLabel.new(pane, "Select a Configuration Item", nil, LAYOUT_LEFT)
          FXHorizontalSeparator.new(pane, SEPARATOR_LINE|LAYOUT_FILL_X)
          switcher = FXSwitcher.new(pane, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          switcher.padLeft = 0
          switcher.padRight = 0
          switcher.padTop = 0
          switcher.padBottom = 0
          @config_frame = switcher

          # Add a first empty pane in the switcher that will appear when no
          # config item is selected
          top_config_pane = FXVerticalFrame.new(switcher, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @top_config_pane_idx = @config_frame.indexOfChild(top_config_pane)

          # Also add a second pane to handle cases where a configurator
          # entry exist but the frame attribute associated with it is nil
          # which means the UI details have not yet been implemented
          tbd_config_pane = FXVerticalFrame.new(switcher, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          FXLabel.new(tbd_config_pane, "Not Implemented Yet.", nil, LAYOUT_FILL_X|LAYOUT_FILL_Y|JUSTIFY_CENTER_X|JUSTIFY_CENTER_Y)
          @tbd_config_pane_idx = @config_frame.indexOfChild(tbd_config_pane)

          plugin["/system/ui/fox/configurator/config_frame"].data = @config_frame

          # Bottom part
          FXHorizontalSeparator.new(vertical, SEPARATOR_RIDGE|LAYOUT_FILL_X)
          btn_box = FXHorizontalFrame.new(vertical,
                                          LAYOUT_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)
          apply_btn = FXButton.new(btn_box, "&Apply", nil, self, 0,
                                   LAYOUT_RIGHT|FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 20, 20)
          cancel_btn = FXButton.new(btn_box, "&Cancel", nil, self, 0,
                       LAYOUT_RIGHT|FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 20, 20)
          ok_btn = FXButton.new(btn_box, "&OK", nil, self, 0,
                       LAYOUT_RIGHT|FRAME_RAISED|FRAME_THICK, 0, 0, 0, 0, 20, 20)
          apply_btn.connect(SEL_COMMAND) do |sender, sel, scn|
            if item = @config_tree.currentItem
              config_slot = @config_tree.getItemData(item)
              config_slot.manager.set_config_properties(config_slot)
            end
          end

	  ok_btn.connect(SEL_COMMAND) do  |sender, sel, scn|
            if item = @config_tree.currentItem
              config_slot = @config_tree.getItemData(item)
              config_slot.manager.set_config_properties(config_slot)
            end
            @current_cfg_slot = nil
            self.handle(self,MKUINT(FXDialogBox::ID_CANCEL,SEL_COMMAND),nil)
          end
          
          cancel_btn.connect(SEL_COMMAND) do |sender, sel, scn|
            @current_cfg_slot = nil
	    self.handle(self,MKUINT(FXDialogBox::ID_CANCEL,SEL_COMMAND),nil)
          end
          self.create
        end
        
        def add_category(config_slot, parent=nil)
          label = config_slot.attr_label
          icon = config_slot.attr_icon
          pane = config_slot.attr_frame
          @plugin.log_info << "Adding entry in Configurator: #{label}"

          # add the new config pane to the switcher and get back to the
          # previously current child
          if pane
            pane.reparent(@config_frame)
          end

          # now add the entry in the config tree list
          node = @config_tree.addItemLast(parent, label, icon,icon)
          @config_tree.killSelection
          if pane
            config_slot.attr_pane_idx = @config_frame.indexOfChild(pane)
          else
            config_slot.attr_pane_idx = @tbd_config_pane_idx
          end

          @config_tree.setItemData(node,config_slot)
          node.create()
          
          # go through sub configuration panes as well if any
          config_slot.each_slot do |slot|
            add_category(slot, node)
          end

          # By default expand all tree items
          @config_tree.expandTree(node)
        end

        def on_selected(sender,sel,item)
          if @current_cfg_slot and @current_cfg_slot.manager.modified?(@current_cfg_slot)
            if @plugin["/system/ui/commands/App/Services/YesNoDialog/"].invoke(
                          @plugin, "Save changes?", "Would you like to save your changes") == "yes"
              @current_cfg_slot.manager.set_config_properties(@current_cfg_slot)
            end
          end
          @current_cfg_slot = @config_tree.getItemData(item)          
          @config_title.text    = @current_cfg_slot.attr_description
          @config_frame.current = @current_cfg_slot.attr_pane_idx          
          @current_cfg_slot.manager.get_config_properties(@current_cfg_slot)
        end

        ##
        # Re-initialize the configurator UI
        # Move all config panes under the main window 
        # except the TBD and the empty one. And clear
        # all items in the selection tree
        def reset()
          main = @plugin["/system/ui/fox/FXMainWindow"].data
          p = @config_frame.childAtIndex(@tbd_config_pane_idx)
          while p = p.next
            p.reparent(main)
          end

          # clear all nodes from the config tree
          @config_tree.clearItems
          @config_tree.create
        end

        ##
        # Make a given config slot the current one in the configurator dialog
        # box. 
        #
        def show_pane(config_slot)
          if config_slot
            frm = config_slot.attr_frame
            idx = @config_frame.indexOfChild(frm)
          else
            idx = @top_config_pane_idx
          end
          @config_frame.current = idx
          show(PLACEMENT_OWNER)
        end

      end # class ConfiguratorDialog

    end #class ConfiguratorRenderer

  end

end
