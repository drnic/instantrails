# Purpose: Setup and initialize the Dock Panes gui interfaces
#
# $Id: dockpane.rb,v 1.11 2005/03/01 11:53:44 ljulliar Exp $
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
# Copyright (c) 2002 Laurent Julliard. All rights reserved.
#

module FreeRIDE
  module FoxRenderer
    
    ##
    # This is the module that renders dockpanes using
    # FOX.
    #
    class DockPane
      extend FreeBASE::StandardPlugin
      ICON_PATH = "/system/ui/icons/DockPane"

      def DockPane.start(plugin)
        component_slot = plugin["/system/ui/components/DockPane"]
        
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end
        
        component_slot.each_slot { |slot| slot.notify(:notify_slot_add) }

        # Handle icons
        plugin[ICON_PATH].subscribe do |event, slot|
          if event == :notify_slot_add
            app = plugin['/system/ui/fox/FXApp'].data
            path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
            if FileTest.exist?(path)
              slot.data = Fox::FXPNGIcon.new(app, File.open(path, "rb").read)
              slot.data.create
            end
          end
        end
    
        # Now only is the plugin ready
        plugin.transition(FreeBASE::RUNNING)
      end

      def DockPane.stop(plugin)
	# When stopping store all the size/position of the undocked pane
	component_slot = plugin["/system/ui/components/DockPane"]
        component_slot.each_slot do |slot|
	  unless slot.manager.docked?
	    slot.manager.save_location
	    # HACK TO AVOID FreeRIDE CRASH at stop time
	    # see the method definition below for more details
	    slot.manager.reparent_to_dockpane
	  end
	end
	
      end

      ##
      # Each instance of this class is responsible for rendering a dockpane component
      #
      class Renderer
        include Fox
        
        FOCUS_COLOR = Fox::FXRGB(0,84,227)
        FOCUS_TEXT_COLOR = FXColor::GhostWhite
        DEFAULT_COLOR = 4292405740
        DEFAULT_TEXT_COLOR = FXColor::Black
        
        attr_reader :plugin
        
        def initialize(plugin, slot)
          @plugin = plugin
          @slot = slot
          
          @main_window = @plugin["/system/ui/fox/FXMainWindow"].data
          @icons = @plugin[ICON_PATH]

          @frame = FXVerticalFrame.new(@main_window, FRAME_NONE|LAYOUT_FILL_Y|LAYOUT_FILL_X,0,0,0,0,0,0,0,0,0,0)

          @sub_frame = FXVerticalFrame.new(@frame, FRAME_NONE|LAYOUT_FILL_Y|LAYOUT_FILL_X,0,0,0,0,0,0,0,0,0,0)

          title_bar = FXHorizontalFrame.new(@sub_frame, FRAME_NONE|LAYOUT_FILL_X,0,0,0,0,0,0,0,0,0,0)
          @title = FXLabel.new(title_bar, @slot.name, nil, JUSTIFY_LEFT|LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_NONE,0,0,0,0)

          @title.setFont(FXFont.new(@plugin["/system/ui/fox/FXApp"].data, "helvetica", 8, FONTWEIGHT_NORMAL))
          @title.setTextColor(FOCUS_TEXT_COLOR)
          @title.frameStyle = FRAME_LINE
          @title.setBorderColor(FOCUS_COLOR)
          @title.setBackColor(FOCUS_COLOR)
          @title.connect(SEL_LEFTBUTTONPRESS) {@slot.data.setFocus}

          # dock/undock and close buttons
          btn_style = (FRAME_NONE|LAYOUT_FILL_Y)
          @dock_btn = FXButton.new(title_bar,"\tUndock\tUndock the plugin", @icons['undock_dockpane'].data, nil, 0, btn_style,0,0,0,0)
          @dock_btn.setBackColor(FOCUS_COLOR)
          @close_btn = FXButton.new(title_bar,"\tClose\tClose the plugin", @icons['close_dockpane'].data, nil, 0, btn_style,0,0,0,0)
          @close_btn.setBackColor(FOCUS_COLOR)

          # create the frame
          @frame.create

          # manage events
          @frame.connect(SEL_FOCUSIN) {
            @title.setTextColor(FOCUS_TEXT_COLOR)
            @title.setBackColor(FOCUS_COLOR)
            @title.setBorderColor(FOCUS_COLOR)
            @close_btn.setBackColor(FOCUS_COLOR)
            @dock_btn.setBackColor(FOCUS_COLOR)
          }
          @frame.connect(SEL_FOCUSOUT) {
            @title.setTextColor(DEFAULT_TEXT_COLOR)
            @title.setBackColor(DEFAULT_COLOR)
            @title.setBorderColor(DEFAULT_COLOR)
            @close_btn.setBackColor(DEFAULT_COLOR)
            @dock_btn.setBackColor(DEFAULT_COLOR)
          }

          @close_btn.connect(SEL_COMMAND, method(:onCmdClose))

          @dock_btn.connect(SEL_COMMAND, method(:onCmdDockUndock))

          @slot.subscribe do |event, slot|
            update(event) if ((event == :refresh) || (event == :notify_data_set && slot==@slot))
          end
          
          setup_actions

	  @plugin.log_info << "DockPane Renderer for #{@slot.path} created"
        end
        
        def setup_actions
          bind_action("dock", :dock)
          bind_action("undock", :undock)
          bind_action("show", :show)
          bind_action("hide", :hide)
          bind_action("current?", :current?)
	  bind_action("save_location", :save_location)
	  bind_action("docked=", :docked=)
	  bind_action("docked?", :docked?)
	  bind_action("reparent_to_dockpane", :reparent_to_dockpane)
        end
        
        def bind_action(name, meth)
          @slot["actions/#{name}"].set_proc method(meth)
        end
        
        ### Commands ###
        
        def dock(dockbar_path)

          # Is it a redock or a first dock?
	  # for a redock the dockpane must be undocked AND a
          # dialog box must exist otherwise it is first time we dock (see below)
          if !self.docked? && !@dlg_box.nil?
	    redock
	    return
          end

          # First time we dock
          @dockbar_path = dockbar_path
          @tabbook = @slot["/system/ui/fox/dockbar/#{self.dockbar_location}/tabbook"].data
          @tab = FXTabItem.new(@tabbook, @slot.name, nil,FRAME_NONE,0,0,0,0,0,0,0,0)
          # keep track of the dockpane manager in the Widget
          @tab.userData = @slot.manager

          if @tabbook.tabStyle==TABBOOK_BOTTOMTABS
            @tab.tabOrientation = TAB_BOTTOM
          else
            @tab.tabOrientation = TAB_TOP
          end
          @tab.hide
          @frame.hide
          @tab.create
          @frame.reparent(@tabbook)
          @tab.connect(SEL_FOCUSIN) {@slot.data.setFocus}

	  # it is the first time we dock it so now that it is docked and 
	  # all is well, let see if we need to undock it to restore previous
	  # session settings
	  if !self.docked?
	    @slot.manager.undock
	  else
	    self.docked = true
	  end
 
          @plugin.log_info << "Reparenting #{@slot.path} to #{dockbar_path}"
        end
        
        def undock

          # Create a separate dialog box the dockpane will appear
          app = @plugin["/system/ui/fox/FXApp"].data

          # create the dialog box and reparent the dockpane frame to it
          @dlg_box = FXDialogBox.new(app,  @slot.name, DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE, 0, 0, @sub_frame.width, @sub_frame.height,0,0,0,0,0,0)
          @dlg_box.connect(SEL_CLOSE, method(:onCmdClose))

          @dlg_box.create

          # make the dockpane disappear from the dockbar
          self.hide

	  # and reparent the dockpane top frame to the dialog box
          @sub_frame.reparent(@dlg_box)
          @dock_btn.icon = @icons['dock_dockpane'].data
	  @dock_btn.tipText = "Dock"
	  @dock_btn.helpText = "Dock the plugin"

	  # size and place as when last undocked, or if nothing to restore
	  # then save the first location chosen by FOX
	  save_location unless restore_location

          #@dlg_box.show
          #@slot.notify(:refresh)

	  # update docked properties and show the pane
	  # in the dialog box
	  self.docked = false
	  self.show

          @slot.notify(:refresh)
        end

        def show
          if @slot.manager.docked?
            @tab.show
            @frame.show
            @tabbook.current = @tabbook.indexOfChild(@tab)/2
            @tab.recalc
            @frame.recalc
            @slot.data.setFocus
          else
            if @dlg_box
              # @dlg_box.raise FIXME: (FXRuby says it's a private method, why????)
	      @dlg_box.show
              @dlg_box.setFocus
            end
          end
	  self.hidden = false
        end
        
        def hide
	  if @slot.manager.docked?
	    @tab.hide
	    @frame.hide
	    @tab.recalc
	    @frame.recalc
	  else
	    # if undocked, simply hide the dialog box
            @dlg_box.hide if @dlg_box
	  end
	  self.hidden = true
        end

        def dockbar_location
          @slot[@dockbar_path].name
        end

	def redock
	  # save the current location/size of the undocked pane
	  save_location

	  # hide the dialog box
	  self.hide

	  # update docked properties to return to dockpane
	  self.docked = true
	  
	  # move it back into the dockpane and update the button title
	  self.reparent_to_dockpane
	  @dock_btn.icon = @icons['undock_dockpane'].data
	  @dock_btn.tipText = "Undock"
	  @dock_btn.helpText = "Undock the plugin"

	  #show it in its new place
	  self.show
	end

	##
	# This method has been created mostly for the purpose of being
	# invoked from the plugin stop method. If an undocked plugin
	# uses combo boxes then when it crashed FreeRIDE when combo boxes
	# objects are released when FR stops. Reparenting the the frame to the
	# original dockpane avoids the crash. NOW THE QUESTION IS WHY DOES IT 
	# CRASH ???
	def reparent_to_dockpane
	  @sub_frame.reparent(@frame)
	end

	def docked?
	  d = @plugin.properties["state/#{@slot.name}/Docked"]
	  #puts "#{@slot.name}: docked? #{d}"
	  d || d.nil?
	end

	def docked=(is_docked)
	  #puts "#{@slot.name}: setting docked to #{is_docked}"
	  @plugin.properties["state/#{@slot.name}/Docked"] = is_docked
	end

	def hidden?
	  h = @plugin.properties["state/#{@slot.name}/Hidden"]
	  #puts "#{@slot.name}: hidden? #{h}"
	  h
	end

	def hidden=(is_hidden)
	  #puts "#{@slot.name}: setting hidden to #{is_hidden}"
	  @plugin.properties["state/#{@slot.name}/Hidden"] = is_hidden
	end

        ##
        # Check whether this is the currently active dockpane
        # 
        def current?
          # current means it is docked, the tab is not hidden
          # and it is the current tab
          @tab && @tab.shown && (@tabbook.current*2 == @tabbook.indexOfChild(@tab))
        end

        ##
        # Called whenever the dockpane may need to be updated
        # in particular when the .data of the slot is
        # modified (meaning that a new graphical object must be
        # inserted in the dockpane
        # 
        def update(event)
          # New visual object to be inserted in the tab frame.
          # slot.data contains the FOX object created by the 
	  # plugin and docked in the dockpane top frame
          if event == :notify_data_set and @slot.data
            child_frame = @slot.data
            child_frame.reparent(@sub_frame)
            child_frame.show
          end
        end
        
        def onCmdClose(sender, sel, ptr)
          if @slot.manager.docked?
            @slot.manager.hide
          else
            # if undocked, redock it first and then hide
            onCmdDockUndock(sender, sel, ptr)
            @slot.manager.hide
          end
          return 1
        end

        def onCmdDockUndock(sender, sel, ptr)
          if @slot.manager.docked?
            @slot.manager.undock
          else
            # close the separate dialog box, redock and 
            # show in dockpane again
            @dlg_box.hide
            @slot.manager.dock(self.dockbar_location)
            @slot.manager.show
            @dlg_box.destroy
            @dlg_box = nil
          end
          return 1
        end

	##
        # Save size and location of the undocked pane in the
        # plugin properties
	def save_location
	  return if @dlg_box.nil?
	  @plugin.properties.auto_save = false
	  @plugin.properties["state/#{@slot.name}/Location/X"] = @dlg_box.x
	  @plugin.properties["state/#{@slot.name}/Location/Y"] = @dlg_box.y
	  @plugin.properties["state/#{@slot.name}/Location/Width"] = @dlg_box.width
	  @plugin.properties["state/#{@slot.name}/Location/Height"] = @dlg_box.height
	  @plugin.properties.auto_save = true
	  @plugin.properties.save
	end

	##
        # Place the undocked pane at the same place and size
        # as it was when last undocked
	# return true if position there was something to restore, false otherwise
	def restore_location
	  x = @plugin.properties["state/#{@slot.name}/Location/X"]
	  y = @plugin.properties["state/#{@slot.name}/Location/Y"]
	  w = @plugin.properties["state/#{@slot.name}/Location/Width"]
	  h = @plugin.properties["state/#{@slot.name}/Location/Height"]
	  #puts "x = #{x}"
	  @dlg_box.position(x,y,w,h) if x
	  return !x.nil?
	end

      end
    end
    
  end
end
