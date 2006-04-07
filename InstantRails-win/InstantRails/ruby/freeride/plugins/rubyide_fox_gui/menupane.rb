# Purpose: Setup and initialize the core gui interfaces
#
# $Id: menupane.rb,v 1.8 2005/09/20 06:11:58 ljulliar Exp $
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

module FreeRIDE
  module FoxRenderer
  
    ##
    # This is the module that renders menupanes using
    # FOX.
    #
    class MenuPane
      include Fox
      
      extend FreeBASE::StandardPlugin
      
      def MenuPane.start(plugin)
        component_slot = plugin["/system/ui/components/MenuPane"]
        
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end
        
        component_slot.each_slot { |slot| slot.notify(:notify_slot_add) }
      
=begin      
        plugin["/system/ui/components/MenuPane"].subscribe do |event, slot|
          Renderer.new(plugin, slot) if event == :notify_data_set
        end
        
        # Force notification events for any slots that existed before we subscribed
        plugin["/system/ui/components/MenuPane"].each_slot { |slot| slot.notify(:notify_data_set) } 
=end        
        # Now only is this plugin running
        plugin.transition(FreeBASE::RUNNING)
      end
      
      ##
      # Each instance of this class is responsible for rendering an menupane component
      #
      class Renderer
        include Fox
        attr_reader :plugin
        
        def initialize(plugin, slot)
          @plugin = plugin
          @slot = slot
          @menu = nil
          @main_window = nil
          
          @command_subscription = Hash.new(nil)
          slot.attr_FXMenuPane = @menu
          @slot.subscribe do |event, slot|
            update(event) if (event == :refresh)
          end
          # Fake a notification event to create the menu pane
          update(:refresh)
        end
        
        ##
        # Called whenever the menupane may need to be updated.
        #
        def update(event)
          # rebuild the menu pane
          @main_window = @plugin["/system/ui/fox/FXMainWindow"].data if (@main_window == nil)
          @menu.detach() unless @menu == nil
          @menu = FXMenuPane.new(@main_window)
          @slot.attr_FXMenuPane = @menu
          @menu_holder = []
          current_menu = @menu
          
          @slot.manager.each_command do | cmd_slot, text, description, available, accelerator |
            begin
              if text == "SEPARATOR"
                cmd_slot.attr_fxmenu = FXMenuSeparator.new(current_menu)
              elsif text == "SUBMENU"
                @menu_holder << current_menu
                current_menu = FXMenuPane.new(@main_window)
              elsif text == "SUBMENU_END"
                oldmenu = current_menu
                current_menu = @menu_holder.pop
                FXMenuCascade.new(current_menu, description, nil, oldmenu)
              else
                build_menu_item(current_menu, cmd_slot, text, description, available, accelerator)
              end
            rescue => e
              puts "\nInternal error creating a menu pane: "  + e + "\n" + e.backtrace.join("\n")
            end
          end
          #create the freshly built menu (FOX needs this)
          @menu.create
          
          # Associate the new menu pane with its menu title if there is one
          if @slot.attr_FXMenuTitle 
            @slot.attr_FXMenuTitle.menu = @menu
          end
        end
        
        
        def build_menu_item(menu, cmd_slot, text, description, available, accelerator)
          menu_text = text
          menu_text += "\t"
          menu_text += accelerator
          menu_text += "\t"
          menu_text += description if description
          menu_text = menu_text.strip

          if cmd_slot.attr_check.nil?
            menu_type = FXMenuCommand
          else
            menu_type = FXMenuCheck
          end

          cmd_slot.attr_fxmenu = menu_type.new(menu, menu_text) do |menuitem|
            menuitem.disable unless available
            menuitem.check = true if cmd_slot.attr_check
            menuitem.connect(SEL_COMMAND) { cmd_slot['actions/select'].invoke }
            subscribe_to_command_slot(cmd_slot, menu, menu_text)
          end
        end
  
        def subscribe_to_command_slot(cmd_slot, menu, menu_text)
          # subscribe to that command slot only if not already done
          # otherwise subscribers accumulate
          return if @command_subscription[cmd_slot]
          
          @command_subscription[cmd_slot] = cmd_slot.subscribe do |event, slot|
            if slot==cmd_slot && event==:notify_attribute_set && !slot.attr_fxmenu.nil?
            
            menuitem = slot.attr_fxmenu

            # check whether enable/disable has changed
            enabled = cmd_slot.attr_enable
            unless enabled.nil?
              if cmd_slot.attr_enable
                menuitem.enable 
              else
                menuitem.disable
              end
            end
			
            # check whether check/uncheck has changed
            # in Fox this means changing the menu entry
            # from FXMenuCommand to FXMenuCheck
            # dynamically
            checked = cmd_slot.attr_check
            unless checked.nil?
              if menuitem.instance_of? FXMenuCommand
                menuitem_new = FXMenuCheck.new(menu,menu_text)
                menuitem_new.connect(SEL_COMMAND) { cmd_slot['actions/select'].invoke }
                menuitem_new.create
                menuitem_new.linkBefore(menuitem)
      
                menuitem.destroy
                cmd_slot.attr_fxmenu = menuitem = menuitem_new
              end
              
              if checked
                menuitem.check = true
              else
                menuitem.check = false
              end
            end #unless
            
            end #unless
          end #block
        end # method subscribe_to_command_slot
      
    end  # class Renderer
      
    end # class MenuPane
    
  end
end  # module FreeRIDE
