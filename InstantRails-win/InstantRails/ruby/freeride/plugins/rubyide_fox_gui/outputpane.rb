# Purpose: Setup and initialize the core gui interfaces
#
# $Id: outputpane.rb,v 1.8 2005/01/08 17:25:20 ljulliar Exp $
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
    # This is the module that renders ediutpanes using
    # FXScintilla.
    #
    class OutputPane
      include Fox
      
      extend FreeBASE::StandardPlugin
      
      
      def self.start(plugin)
        component_slot = plugin["/system/ui/components/OutputPane"]
        
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end
        
        component_slot.each_slot { |slot| slot.notify(:notify_slot_add) }

        cmd_mgr = plugin["/system/ui/commands"].manager
        cmd_mgr.add("App/View/Output", "Output Window", "View Output Window") do |cmd_slot|
          plugin['/system/ui/current/OutputPane'].manager.toggle
        end
        key_mgr = plugin["/system/ui/keys"].manager
        key_mgr.bind("App/View/Output", :F8)

        viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
        viewmenu.add_command("App/View/Output")
        viewmenu.uncheck("App/View/Output")
        
        plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if slot.data == true
            if plugin.properties["Open"]
              plugin['/system/ui/current/OutputPane'].manager.show
            else
              plugin['/system/ui/current/OutputPane'].manager.hide
            end
          end
        end
        
        # Now only is this plugin running
        plugin.transition(FreeBASE::RUNNING)
      end
      
      class Renderer
        include Fox
        
        attr_reader :plugin
        
        def initialize(plugin, slot)
          @plugin = plugin
          @slot = slot
          main_window = @plugin["/system/ui/fox/FXMainWindow"].data
          @viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
          @frame = FXVerticalFrame.new(main_window, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @selector = FXComboBox.new(@frame, 5, nil, 0, COMBOBOX_INSERT_LAST|FRAME_THICK|LAYOUT_FILL_X)
	  @selector.setNumVisible(5)
          @textarea = FXText.new(@frame, nil, 0, TEXT_READONLY|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK)
          #@textarea.font = FXFont.new(main_window.getApp, "courier", 10)
	  @textarea.connect(SEL_KEYPRESS, method(:onKeyPTextConsole))
          @textarea.tabColumns=2
          setup_styles
          @selector.connect(SEL_COMMAND) do 
            getFormattedText(@selector.getItemText(@selector.currentItem)).render
          end
          @frame.hide
          @frame.create

          # attach the slot to the 2 tabitem widget and the renderer to the
          # scintilla controller s so that they both know to which higher
          # level object they belong to
          @dockpane_slot = plugin['/system/ui/components/DockPane'].manager.add("Output View")
          @dockpane_slot.data = @frame
          setup_actions

          # When the dockpane informs us that it is opened or closed
          # adjust the menu item and properties accordingly 
          @dockpane_slot["status"].subscribe do |event, slot|
            if event == :notify_data_set
              if @dockpane_slot["status"].data == 'opened'
                @checked = true
                @viewmenu.check("App/View/Output")
                @plugin.properties["Open"] = true
              elsif @dockpane_slot["status"].data == 'closed'
                @viewmenu.uncheck("App/View/Output")
                @checked = false
                @plugin.properties["Open"] = false
              end
            end
          end

          @plugin.log_info << "OutputPane Renderer plugin started"

          # Dock it now that everything is ready
          @dockpane_slot.manager.dock('south')

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
        end
        
        def hide
          @dockpane_slot.manager.hide
        end

	def attach_input(method)
	  @input_method = method
	end

	def onKeyPTextConsole(sender, sel, ptr)
	  #HACK: this is a quick hack to leave it FOX to manage all
	  # special characters (RETURN, BS, DEL, Arrow keys,....).
	  # Can we do better than that?
	  if ( ptr.text.length>0 && ptr.text[0] >= 32)
	    @textarea.appendStyledText(ptr.text, 3)
	    ret = 1
	  else
	    # returning 0 makes the FXText widget handle the char itself
	    ret = 0
	  end

	  # send the input to the plugin who manages this output
	  # pane and delcared interest for keyboard input
	  @input_method.call(ptr.text) if @input_method
	  return ret
	end

        def setup_styles
          #Normal color
          hs1 = FXHiliteStyle.new
          hs1.normalForeColor = FXColor::Black
          hs1.normalBackColor = FXColor::White
          hs1.selectForeColor = @textarea.selTextColor
          hs1.selectBackColor = @textarea.selBackColor
          hs1.hiliteForeColor = @textarea.hiliteTextColor
          hs1.hiliteBackColor = @textarea.hiliteBackColor
          hs1.activeBackColor = @textarea.activeBackColor
          hs1.style = 0
          #Command executed
          hs2 = FXHiliteStyle.new
          hs2.normalForeColor = FXColor::Blue
          hs2.normalBackColor = FXColor::White
          hs2.selectForeColor = @textarea.selTextColor
          hs2.selectBackColor = @textarea.selBackColor
          hs2.hiliteForeColor = @textarea.hiliteTextColor
          hs2.hiliteBackColor = @textarea.hiliteBackColor
          hs2.activeBackColor = @textarea.activeBackColor
          hs2.style = 0
          #Error
          hs3 = FXHiliteStyle.new
          hs3.normalForeColor = FXColor::Red
          hs3.normalBackColor = FXColor::White
          hs3.selectForeColor = @textarea.selTextColor
          hs3.selectBackColor = @textarea.selBackColor
          hs3.hiliteForeColor = @textarea.hiliteTextColor
          hs3.hiliteBackColor = @textarea.hiliteBackColor
          hs3.activeBackColor = @textarea.activeBackColor
          hs3.style = 0
          
          # Enable the style buffer for this text widget
          @textarea.styled = true
          
          # Set the styles
          @textarea.hiliteStyles = [hs1, hs2, hs3]
        end
        
        def getFormattedText(name)
          result = nil
          @selector.each {|item, value| result = value if item==name}
          unless result
            result = FormattedText.new(@textarea)
            @selector.appendItem(name, result)
          end
          0.upto(@selector.numItems - 1) do |i|
            if name == @selector.getItemText(i)
              @selector.currentItem=i
              break
            end
          end
          return result
        end
        
        def setup_actions
          bind_action("clear", :clear)
          bind_action("set", :set)
          bind_action("append", :append)
          bind_action("show", :show)
          bind_action("hide", :hide)
          bind_action("toggle", :toggle)
          bind_action("attach_input", :attach_input)
        end
        
        def bind_action(name, meth)
          @slot["actions/#{name}"].set_proc method(meth)
        end
        
        ### Commands ###
        
        def set(name, text)
          getFormattedText(name).set(text).render
        end
        
        def append(name, text)
          getFormattedText(name).append(text).render
        end
        
        def clear(name)
          getFormattedText(name).clear.render
        end
        
      end  # class Renderer
      
      class FormattedText
      
        def initialize(textarea)
          @textarea = textarea
          clear
        end
        
        def set(text)
          clear
          parse(text)
          self
        end
        
        def append(text)
          parse(text)
          self
        end
        
        def clear
          @text = []
          @styles = []
          @last_rendered = 0
          @textarea.text = ''
          self
        end
        
        def render
          @last_rendered.upto(@text.size-1) do |i|
            @textarea.appendStyledText(@text[i], @styles[i])
          end
          @last_rendered = @text.size
          @textarea.makePositionVisible(@textarea.text.size)
          @textarea.update # force a repaint in sync (needed by script runner)
          @textarea.repaint
          self
        end
        
        private
        
        def parse(text)
          if text[0,5]=='<CMD>'
            @text << text[5..-1]
            @styles << 2
          else
            style = 1
            content = ""
            text.each_line do |line|
              if style==1
                if line =~ /\.rb:[0-9]+/
                  @text << content
                  @styles << style
                  content = ""
                  style = 3
                end
              elsif style==3
                unless line =~ /\.rb:[0-9]+/
                  @text << content
                  @styles << style
                  content = ""
                  style = 1
                end
              end
              content += line
            end
            unless content==""
              @text << content
              @styles << style
            end
          end
        end
        
      end
      
    end

  end
end
