# Purpose: Examine and debug the FreeBASE databus
#
# $Id: databus_inspector.rb,v 1.5 2005/10/09 19:13:52 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Laurent Julliard All rights reserved.
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
    class DatabusInspector
      include Fox
      extend FreeBASE::StandardPlugin
      
      def DatabusInspector.start(plugin)
        # Add command
        plugin["/system/ui/commands"].manager.add("App/Tools/DBI","&Databus Inspector") do |cmd_slot|
          DatabusWindow.new(plugin.core.bus)
        end
        plugin["/system/ui/keys"].manager.bind("App/Tools/DBI", :ctrl, :D)
        
        # Insert the inspector in the Tools menu
        toolsmenu = plugin["/system/ui/components/MenuPane/Tools_menu"].manager
        toolsmenu.add_command("App/Tools/DBI")
        plugin.transition(FreeBASE::RUNNING)
      end
      
      class DatabusWindow < FXDialogBox
        include Fox
        
        def initialize(bus)
          app = bus["/system/ui/fox/FXApp"].data
          
          # Call base class initializer first (a new FXMainWindow)
          super(app, "Databus Inspector", DECOR_ALL)
          self.width = 800
          self.height = 550
          
          self.connect(SEL_CLOSE) { self.destroy }
        
          # Contents
          contents = FXSplitter.new(self, 
            (LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_VERTICAL|SPLITTER_REVERSED)
          )
          
          # Horizontal splitter
          splitter = FXSplitter.new(contents, 
            (LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_HORIZONTAL)
          )
          
          # Create a sunken frame to hold the tree list
          groupbox = FXGroupBox.new(splitter, "Databus",
             LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE
          )
             
          frame = FXVerticalFrame.new(groupbox,
             LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK
          )
            
          # Create the empty tree list and give it to a reasonable width
          @treeList = FXTreeList.new(frame, nil, 0,
            (TREELIST_BROWSESELECT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          )
          groupbox.setWidth(@treeList.font.getTextWidth('M'*20))
        
          # Fill it up based on the tree contents
          populateTree(@treeList, nil, bus['/'])
          @treeList.expandTree(@treeList.firstItem)
        
          # create the refresh button
          refreshButton = FXButton.new(frame, "Refresh",  nil, app, FXApp::ID_QUIT,(BUTTON_NORMAL|LAYOUT_FILL_X))
          refreshButton.connect(SEL_COMMAND) do |sender, sel, item|
            @treeList.clearItems
            populateTree(@treeList, nil, bus['/'])
            @treeList.forceRefresh
          end
          
          
          # Create Table list
          tableFrame = FXVerticalFrame.new(splitter,(LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK))
          #table = FXTable.new(tableFrame,5,2,nil,0, (FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y))
          view = FXText.new(tableFrame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          invokeButton = FXButton.new(tableFrame, "Invoke Command",  nil, app, 0,(BUTTON_NORMAL|LAYOUT_FILL_X))
          invokeButton.connect(SEL_COMMAND) do |sender, sel, item|
            bus[@current_bus_path].invoke(bus[@current_bus_path])
          end
          invokeButton.hide
          
          # What happens when clicking on a node 
          @treeList.connect(SEL_COMMAND) do |sender, sel, treeItem|
            app.beginWaitCursor
            @current_bus_path = treeItem.path
            view.setText(formatSlot(bus[@current_bus_path]))
            if @current_bus_path.include?('ui/commands') and bus[@current_bus_path].is_proc_slot?
              invokeButton.show
            else
              invokeButton.hide
            end
            app.endWaitCursor
          end
        
          # Tabbed notebook at the bottom
          tabBook = FXTabBook.new(contents, nil, 0, LAYOUT_FILL_X)
          tabBook.height = self.height/4
        
          tab1 = FXTabItem.new(tabBook, "Log")
          page1 = FXHorizontalFrame.new(tabBook, FRAME_RAISED)
          frame1 = FXHorizontalFrame.new(page1,
            FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y
          )
        
          tab2 = FXTabItem.new(tabBook, "Events")
          page2 = FXHorizontalFrame.new(tabBook, FRAME_RAISED)
          frame2 = FXHorizontalFrame.new(page2,
            FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y
          )
          
          log = FXText.new(frame1, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          log.editable = false
        
          # hijiack the existing logger if any (a proc must be associated 
          # to the /log slot). Do our own log and call the original proc
          log_slot = bus['/log']
          if log_slot.is_proc_slot?
            @log_proc = log_slot.proc.get_proc
            log_slot.proc.set_proc do |logType, message|
              log.appendText("#{logType}:  #{message}\n")
              @log_proc.call(logType, message)
            end
          end
            
          # subscribe to the root slot so that we are notified with all events
          events = FXText.new(frame2, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          events.editable = false
          bus['/'].subscribe do |event, slot|
              events.appendText("Received '#{event}' on slot #{slot.path}\n")
          end
        
          # create and show the whole thing
          self.create
          self.show(PLACEMENT_OWNER)
        end
        
        # Recursively fill up the tree list
        def populateTree(treeList, rootItem, rootNode)
          rootNode.each_slot do |slot|
            childItem = treeList.addItemLast(rootItem, slot.name)
            populateTree(treeList, childItem, slot)
          end
        end
        
        # Format slot characteristics
        def formatSlot(slot)
          out = "Slot:  #{slot.path}\n"
					# Add the slot's manager
          out << "\nManager: #{slot.manager}\n"					
					# Add the count of subscribers
          out << "Subscribers: #{slot.subscribers.size}\n"					
          if slot.is_data_slot?
            out << "\nType:  DATA\n"
            out << "\nValue:\n#{slot.data.inspect}\n"
          elsif slot.is_queue_slot?
            out << "\nType:  QUEUE\n"
            out << "Size: "
            if slot.count != 0
              out << "#{slot.count}\n\nValues:\n"
              for i in 0..slot.count-1
                out << "[#{i}]: #{slot.queue[i].inspect}\n"
              end
            else
              out << "Empty\n"
            end
          elsif slot.is_stack_slot?
            out << "\nType:  STACK\n"
            out << "Size:   #{slot.count}\n"
          elsif slot.is_proc_slot?
            out << "\nType:  PROC\n"
          else
            out << "\nType:  -\n"
          end
          # Now format attributes if any
          out << "\nAttributes:\n"
          if ( slot.attrs == nil || slot.attrs.size == 0)
            out << "None\n"
          else
            slot.attrs.each do |k,v| 
              out << "   - #{k}: #{v}\n"
            end
          end
          return out
        end # method format
      
      end # class DatabusWindow
    
    end #class DatabusInspector

  end
end


##
# Override general FX_TreeItem behavior
#
module Fox
  class FXTreeItem
    def path
      path = '' ; item=self
      begin
        path = '/'+item.to_s + path 
      end while (item = item.parent)
      return path
    end
  end
end
