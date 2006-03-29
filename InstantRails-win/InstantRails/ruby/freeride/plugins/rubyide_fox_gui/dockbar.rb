# Purpose: Setup and initialize the dock bar gui interfaces
#
# $Id: dockbar.rb,v 1.6 2004/10/19 22:13:47 ljulliar Exp $
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
    # This is the class that renders dockbars using
    # FOX.
    #
    class DockBar
      extend FreeBASE::StandardPlugin
      
      def DockBar.start(plugin)
        component_slot = plugin["/system/ui/components/DockBar"]
        
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end
        
        component_slot.each_slot { |slot| slot.notify(:notify_slot_add) }
        
        # Now only is the plugin ready
        plugin.transition(FreeBASE::RUNNING)
      end
      
      ##
      # Each instance of this class is responsible for rendering a dockbar component
      #
      class Renderer
        include Fox
        attr_reader :plugin, :tab, :frame
        
        def initialize(plugin, slot)
          @plugin = plugin
          @slot = slot
          @where = @slot.name # east, west, south
          @resizeWidth = @plugin.properties["West/Width"]
          @resizeHeight = @plugin.properties["South/Height"]
          @resizeWidth ||= 200
          @resizeHeight ||= 200
          @plugin.log_info << "DockBar #{@slot.name} started"
          
          db_slot = plugin["/system/ui/fox/dockbar/#{@where}"]
          @parentFrame = db_slot["frame"].data
          
          case @where
          when 'west'
            @parentFrame.width = 0 if @parentFrame.width < 6
            @tb = FXTabBook.new(@parentFrame, nil, 0,
              (LAYOUT_SIDE_LEFT|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABBOOK_BOTTOMTABS)
            )
            @parentFrame.connect(SEL_UPDATE) do |sender, sel, ptr|
              if @parentFrame.width > 6 && @parentFrame.width != @resizeWidth && sender == @parentFrame
                @resizeWidth = @parentFrame.width
                @plugin.properties["West/Width"] = @resizeWidth
              end
              0
            end
          when 'south'
            @parentFrame.height = 0 if @parentFrame.height < 6 
            @tb = FXTabBook.new(@parentFrame, nil, 0,
              (LAYOUT_FILL_X| LAYOUT_FILL_Y|TABBOOK_BOTTOMTABS)
            )
            @parentFrame.connect(SEL_UPDATE) do |sender, sel, ptr|
              if @parentFrame.height > 6 && @parentFrame.height != @resizeHeight && sender == @parentFrame
                @resizeHeight = @parentFrame.height
                @plugin.properties["South/Height"] = @resizeHeight
              end
              0
            end
          else
            @plugin.log_error << "unknow dockbar '#{@where}'"
          end
          @tb.padRight = 0
          @tb.padTop = 0
          @tb.padLeft = 0
          @tb.padBottom = 0
          
          @tb.create if @tb
          db_slot["tabbook"].data = @tb
          setup_actions
          @plugin.log_info << "DockBar #{@slot.name} created"
        end
        
        def setup_actions
          bind_action("show", :show)
          bind_action("hide", :hide)
                bind_action("current", :current)
        end
        
        def bind_action(name, meth)
          @slot["actions/#{name}"].set_proc method(meth)
        end
        
        def show
          all_hidden = true
          (@tb.numChildren-1).downto(0) do |i|
            tab = @tb.childAtIndex(i)
            if (tab.kind_of? Fox::FXTabItem) && tab.shown
              all_hidden = false; break
            end
          end
          return if all_hidden

          case @where
          when 'west'
            if @parentFrame.width < 20 
              @parentFrame.width = @resizeWidth
              @parentFrame.show
            end
          when 'south'
            if @parentFrame.height < 20
              @parentFrame.height = @resizeHeight
              @parentFrame.show
            end
          end
        end
        
        def hide
          (@tb.numChildren-1).downto(0) do |i|
            tab = @tb.childAtIndex(i)
            return if (tab.kind_of? Fox::FXTabItem) && tab.shown
          end
          case @where
          when 'west'
            @resizeWidth = @parentFrame.width unless @parentFrame.width==0
            @parentFrame.width = 0
            @parentFrame.hide
          when 'south'
            @resizeHeight = @parentFrame.height unless @parentFrame.height==0
            @parentFrame.height = 0
            @parentFrame.hide
          end
        end

        ##
        # return the dockpane object (manager) that is currently
        # visible in this DockBar
        #
        def current
          @tb.childAtIndex(@tb.getCurrent).userData
        end
      end
    end
    
  end
end
