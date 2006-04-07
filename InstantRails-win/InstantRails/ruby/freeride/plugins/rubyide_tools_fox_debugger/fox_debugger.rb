# Purpose: Setup and initialize the dock bar gui interfaces
#
# $Id: fox_debugger.rb,v 1.26 2005/02/20 08:04:01 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org>
# Contributors: Richard Kilmer <rich@infoether.com>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Laurent Julliard. All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end
require 'fox12/colors'
require 'rubyide_tools_fox_debugger/fox_debugger_configurator'

module FreeRIDE
  module FoxRenderer

    ##
    # This is the module that renders debuggers using
    # FOX.
    #
    module DebuggerRenderFox
      include Fox
      extend FreeBASE::StandardPlugin
      ICON_PATH = "/system/ui/icons/Debugger"
      @@debugRenderer = nil

      def DebuggerRenderFox.start(plugin)

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

        # Create a renderer for each new Debugger session
        plugin["/system/ui/components/Debugger"].subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent.name == 'Debugger')
            @@debugRenderer = Renderer.new(plugin, slot)
          end
        end
        
        plugin["/system/ui/components/Debugger"].each_slot do |slot|
          @@debugRenderer = Renderer.new(plugin, slot)
        end
        # @@debugRenderer = Renderer.new(plugin,slot)
        
        # Add command to Show/Hide the debugger - Command only 
        # available when debugger session exists
        cmd = plugin["/system/ui/commands"].manager.add("App/View/Debugger","Debugger","View Debugger") do |cmd_slot|
          @@debugRenderer.toggle
        end
        plugin["/system/ui/keys"].manager.bind("App/View/Debugger", :F8)

        cmd.availability = plugin['/system/ui/current'].has_child?('Debugger')
        cmd.manage_availability do |command|
          plugin['/system/ui/current'].subscribe do |event, slot|
            if slot.name=="Debugger"
              case event
              when :notify_slot_link
                command.availability=true
              when :notify_slot_unlink
                command.availability=false
              end
            end
          end
        end

        # Add command to start the debugger from the toolbar       
        plugin["/system/ui/commands"].manager.command("App/Run/Debugger").icon = "/system/ui/icons/Debugger/startDebugger"
        plugin["/system/ui/current/ToolBar"].manager.add_command("Run", "App/Run/Debugger")
        
        # Insert the inspector in the Tools menu
        viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
        viewmenu.add_command("App/View/Debugger")
        viewmenu.uncheck("App/View/Debugger")
        
        # Initialize configurator UI for the debugger
        DebuggerConfiguratorRenderer.new(plugin)

        plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
          if slot.data == true
            if plugin.properties["Open"]
              plugin["/system/ui/components/Debugger"].manager.add
              plugin["/system/ui/current/Debugger"].manager.show
            end
          end
        end
        
        # Now only is the plugin ready
        plugin.transition(FreeBASE::RUNNING)
      end

      # true: capture IO through FOX handlers, false: run a Ruby thread
      VIA_FOX = true
  
      ##
      # Each instance of this class is responsible for rendering a debugger component
      #
      class Renderer < FXHorizontalFrame
        include Fox
        attr_reader :plugin
       
        def initialize(plugin,slot)
          @plugin = plugin
          @slot = slot
          @cmd_mgr = plugin['/system/ui/commands'].manager
          @viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
          @icons = @plugin[ICON_PATH]
          @app = plugin['/system/ui/fox/FXApp'].data

          # Create the frame for this plugin, attach it to the main window. 
          # It will be reparented later on when the debugger is inserted
          # in a dockpane.  Also hide it because we don;t want to see it now.
          main = plugin["/system/ui/fox/FXMainWindow"].data
          @frm = super(main, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,0,0,0,0,0,0,0,0)
          @frm.hSpacing = 0
          @frm.vSpacing = 0
          create_ui()
          @frm.hide
          @frm.create
          # @slot.subscribe do |event, slot|
          #  update(event,slot) if event == :notify_data_set
          #end
          @dockpane_slot = plugin['/system/ui/components/DockPane'].manager.add("Debugger")
          @dockpane_slot.data = @frm

          setup_actions()

          # When the dockpane informs us that it is opened or closed
          # adjust the menu item and properties accordingly 
          @dockpane_slot["status"].subscribe do |event, slot|
            if event == :notify_data_set
              if @dockpane_slot["status"].data == 'opened'
                @checked = true
                @viewmenu.check("App/View/Debugger")
                @plugin.properties["Open"] = true
              elsif @dockpane_slot["status"].data == 'closed'
                @viewmenu.uncheck("App/View/Debugger")
                @checked = false
                @plugin.properties["Open"] = false
              end
            end
          end

          @plugin.log_info << "Debugger renderer created #{slot.path}"

          # Dock it now that everything is ready
          @dockpane_slot.manager.dock('south')

        end

        def setup_actions
          bind_action("print_stderr", :print_stderr)
          bind_action("attach_stderr", :attach_stderr)
          bind_action("attach_stdin", :attach_stdin)
          bind_action("attach_stdout", :attach_stdout)
          bind_action("detach_stderr", :detach_stderr)
          bind_action("detach_stdin", :detach_stdin)
          bind_action("detach_stdout", :detach_stdout)
          bind_action("update_thread_list", :update_thread_list)
          bind_action("update_frame_list", :update_frame_list)
          bind_action("update_local_var_list", :update_local_var_list)
          bind_action("update_global_var_list", :update_global_var_list)
          bind_action("list_watchpoints", :list_watchpoints)
          bind_action("start", :start)
          bind_action("stop", :stop)
          bind_action("close", :close)
          bind_action("toggle", :toggle)
          bind_action("hide", :my_hide)
          bind_action("show", :my_show)
          bind_action("clear", :clear)
          bind_action("show_config", :show_config)
        end
        
        def bind_action(name, meth)
          @slot["actions/#{name}"].set_proc method(meth)
        end

        def my_show
          @dockpane_slot.manager.show
        end

        def my_hide
          @dockpane_slot.manager.hide
        end

        def toggle
          # hide it if visible, show it if invisible
          @checked ? my_hide : my_show
        end

        ##
        # Clear the console output
        #
        def clear
          @console.text = ""
          @console.makePositionVisible(0)
        end

        ##
        # Create the debugger UI and put it in a top frame
        #
        def create_ui
        
          # now build the inside of the top frame
          mx = FXMatrix.new(@frm,2, FRAME_NONE|MATRIX_BY_COLUMNS|PACK_UNIFORM_WIDTH|LAYOUT_FILL_Y,0,0,0,0,0,0,0,0,0,0)
        
          style = (BUTTON_TOOLBAR|BUTTON_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FILL_COLUMN)
          FXButton.new(mx, "\tDebug\tDebug the program.",
                 @icons['startDebugger'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdStart))
                 button.connect(SEL_UPDATE, method(:onUpdStart))
          end
                 
          FXButton.new(mx, "\tStep Over\tStep to the next line in this file.",
                 @icons['stepOver'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdStepOver))
                 button.connect(SEL_UPDATE, method(:onUpdStepOver))
          end
                 
          FXButton.new(mx, "\tResume Program\tResume Program Execution.",
                 @icons['resume'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdResume))
                 button.connect(SEL_UPDATE, method(:onUpdResume))
          end
                 
          FXButton.new(mx, "\tStep Into\tStep into the next executed line",
                 @icons['stepInto'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdStepIn))
                 button.connect(SEL_UPDATE, method(:onUpdStepIn))
          end
                 
          FXButton.new(mx, "\tPause Program\tSuspend program execution and start deugging.",
                 @icons['pause'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdPause))
                 button.connect(SEL_UPDATE, method(:onUpdPause))
          end
                 
          FXButton.new(mx, "\tStep Out\tStep to the first line after exiting this method.",
                 @icons['stepOut'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdStepOut))
                 button.connect(SEL_UPDATE, method(:onUpdStepOut))
          end

                 
          FXButton.new(mx, "\tTerminate Program\tTerminate the debugging session.",
                 @icons['suspend'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdStop))
                 button.connect(SEL_UPDATE, method(:onUpdStop))
          end

                 
          FXButton.new(mx, "\tRun to Cursor\tRun to the line where the text cursor is.",
                 @icons['runToCursor'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdRunToCursor))
                 button.connect(SEL_UPDATE, method(:onUpdRunToCursor))
          end

                 
          FXButton.new(mx, "\tClose\tClose the debugger plugin.",
                 @icons['cancel'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdClose))
          end

                 
          FXButton.new(mx, "\tShow Execution Point\tShow the current execution point in the editor.",
                 @icons['showCurrentFrame'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdShowExecPoint))
                 button.connect(SEL_UPDATE, method(:onUpdShowExecPoint))
          end

        
          FXButton.new(mx, "\tHelp\tHelp",
                 @icons['help'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdHelp))
          end

        
          FXButton.new(mx, "\tView Breakpoints\tList and manage all breakpoints and watchpoints.",
                 @icons['viewBreakpoints'].data, self, 0, style) do |button|
                 button.connect(SEL_COMMAND, method(:onCmdViewBreakpoints))
                 button.connect(SEL_UPDATE, method(:onUpdViewBreakpoints))
          end
        
          tb = FXTabBook.new(@frm, nil, 0, (LAYOUT_SIDE_LEFT|
            LAYOUT_FILL_X|LAYOUT_FILL_Y|TABBOOK_TOPTABS),0,0,0,0,0,0,0,0)
        
          # create the text console tab
          tconsole = FXTabItem.new(tb,"Console",nil)
          fconsole = FXVerticalFrame.new(tb,FRAME_RIDGE|FRAME_THICK)
          fconsole.padLeft = 0; fconsole.padRight = 0
          fconsole.padTop = 0; fconsole.padBottom = 0
          @console = FXText.new(fconsole, self, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @console.connect(SEL_KEYPRESS, method(:onKeyPTextConsole))
          scons_frame = FXHorizontalFrame.new(fconsole, LAYOUT_FILL_X)
          scons_frame.padLeft = 0; scons_frame.padRight = 0
          scons_frame.padTop = 0; scons_frame.padBottom = 0

          FXLabel.new(scons_frame, "Eval:", nil, JUSTIFY_LEFT|LAYOUT_CENTER_Y)
          @eval_tf = FXTextField.new(scons_frame, 2, nil, 0, (FRAME_SUNKEN|
            LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
          @eval_tf.connect(SEL_COMMAND, method(:onCmdEvalExpr))
 


          # Define text styles for STDOUT (index 1)  and STDERR (index 2) output
          # and STDIN (index 3)
          hsout = FXHiliteStyle.new
          hsout.normalForeColor = FXColor::DarkBlue
          hsout.normalBackColor = @console.backColor
          hsout.selectForeColor = @console.selTextColor
          hsout.selectBackColor = @console.selBackColor
          hsout.hiliteForeColor = @console.hiliteTextColor
          hsout.hiliteBackColor = @console.hiliteBackColor
          hsout.activeBackColor = @console.activeBackColor
          hsout.style = 0
        
          hserr = FXHiliteStyle.new
          hserr.normalForeColor = FXColor::Red
          hserr.normalBackColor = @console.backColor
          hserr.selectForeColor = @console.selTextColor
          hserr.selectBackColor = @console.selBackColor
          hserr.hiliteForeColor = @console.hiliteTextColor
          hserr.hiliteBackColor = @console.hiliteBackColor
          hserr.activeBackColor = @console.activeBackColor
          hserr.style = 0
        
          hsin = FXHiliteStyle.new
          hsin.normalForeColor = FXColor::SeaGreen
          hsin.normalBackColor = @console.backColor
          hsin.selectForeColor = @console.selTextColor
          hsin.selectBackColor = @console.selBackColor
          hsin.hiliteForeColor = @console.hiliteTextColor
          hsin.hiliteBackColor = @console.hiliteBackColor
          hsin.activeBackColor = @console.activeBackColor
          hsin.style = FXText::STYLE_UNDERLINE
        
          # Define an output style for evaluated expressions
          hseval = FXHiliteStyle.new
          hseval.normalForeColor = FXColor::DarkSlateGray
          hseval.normalBackColor = @console.backColor
          hseval.selectForeColor = @console.selTextColor
          hseval.selectBackColor = @console.selBackColor
          hseval.hiliteForeColor = @console.hiliteTextColor
          hseval.hiliteBackColor = @console.hiliteBackColor
          hseval.activeBackColor = @console.activeBackColor
        
        
          @console.styled = true
          @console.hiliteStyles = [hsout, hserr, hsin, hseval]
        
          # create the thread display tab
          tab_thread = FXTabItem.new(tb,"Threads",nil)
          frm_thread = FXHorizontalFrame.new(tb,FRAME_RIDGE|FRAME_THICK)
          frm_thread.padLeft = 0; frm_thread.padRight = 0
          frm_thread.padTop = 0; frm_thread.padBottom = 0
	  FXLabel.new(frm_thread,"Not yet implemented",nil, JUSTIFY_NORMAL|LAYOUT_CENTER_X|LAYOUT_CENTER_Y)
          
          # create the frame display tab
          tab_frame = FXTabItem.new(tb,"Frames",nil)
          frm_frame = FXVerticalFrame.new(tb,FRAME_RIDGE|FRAME_THICK|
                    LAYOUT_FILL_X|LAYOUT_FILL_Y)
          frm_frame.padLeft = 0; frm_frame.padRight = 0
          frm_frame.padTop = 0; frm_frame.padBottom = 0
          split_frame = FXSplitter.new(frm_frame, LAYOUT_FILL_X|
            SPLITTER_TRACKING|SPLITTER_HORIZONTAL)
          
          @cbox_frame = FXComboBox.new(split_frame,5,self,0,
              COMBOBOX_STATIC|LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
	  @cbox_frame.setNumVisible(5)
          #@cbox_frame.appendItem("Frame 1")
          #@cbox_frame.appendItem("Frame 2")
          @cbox_frame.connect(SEL_COMMAND, method(:onCmdFrameSelect))
         
          @cbox_thread = FXComboBox.new(split_frame,5,self,0,
                     COMBOBOX_STATIC|LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
	  @cbox_thread.setNumVisible(5)
          #@cbox_thread.appendItem("Thread 1")
          #@cbox_thread.appendItem("Thread 2")
          @cbox_thread.connect(SEL_COMMAND, method(:onCmdThreadSelect))
         
          frmc_frame = FXHorizontalFrame.new(frm_frame,FRAME_RIDGE|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	  frmc_frame.padLeft = 0; frmc_frame.padRight = 0; 
	  frmc_frame.padTop = 0; frmc_frame.padBottom = 0; 
          @cbox_frame.width = frm_frame.width/2
          @cbox_thread.width = frm_frame.width/2
          @tbox_lvar = FXText.new(frmc_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @tbox_lvar.editable = false

          # create the watches display tab
          tab_watches = FXTabItem.new(tb,"Watches",nil)
          frm_watches = FXVerticalFrame.new(tb,FRAME_RIDGE|FRAME_THICK)
          frm_watches.padLeft = 0; frm_watches.padRight = 0
          frm_watches.padTop = 0; frm_watches.padBottom = 0
          frm_listw = FXHorizontalFrame.new(frm_watches, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @watch_list = FXList.new(frm_listw, nil, 0,
            LIST_SINGLESELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
	  @watch_list.setNumVisible(1)
          delw_button = FXButton.new(frm_listw,"Delete",nil,self,
            FRAME_RAISED|FRAME_THICK|LAYOUT_SIDE_LEFT|LAYOUT_CENTER_Y)
          delw_button.connect(SEL_COMMAND, method(:onCmdDeleteWatchPoint))
 
          frm_addw = FXHorizontalFrame.new(frm_watches, LAYOUT_FILL_X)
          frm_addw.padLeft = 0; frm_addw.padRight = 0
          frm_addw.padTop = 0; frm_addw.padBottom = 0

          FXLabel.new(frm_addw, "Watch:", nil, JUSTIFY_LEFT|LAYOUT_CENTER_Y)
          @watch_tf = FXTextField.new(frm_addw, 2, nil, 0, (FRAME_SUNKEN|
            LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
          @watch_tf.connect(SEL_COMMAND, method(:onCmdAddWatchPoint))
          addw_button = FXButton.new(frm_addw,"  Add  ",nil,self,
            FRAME_RAISED|FRAME_THICK|LAYOUT_SIDE_LEFT|LAYOUT_CENTER_Y)
          addw_button.connect(SEL_COMMAND, method(:onCmdAddWatchPoint))
 
          # create the global variables display tab
          tab_globals = FXTabItem.new(tb,"Globals",nil)
          frm_globals = FXHorizontalFrame.new(tb,FRAME_RAISED|FRAME_THICK)
          frm_globals.padLeft = 0; frm_globals.padRight = 0
          frm_globals.padTop = 0; frm_globals.padBottom = 0
 
          @table_gvar = FXTable.new(frm_globals, nil, 0, TABLE_COL_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @table_gvar.columnHeaderHeight = 0;
          @table_gvar.rowHeaderWidth = 0;
          #@tbox_gvar = FXText.new(frm_globals, self, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
        end
  
        ##
        # Update the local var list (text box)
        #
        def update_local_var_list(lv_ary)
          @tbox_lvar.text=''
          lv_ary.keys.sort.each { |v|
            #puts "#{v} => #{lv_ary[v]}\n"
            @tbox_lvar.appendText("#{v} => #{lv_ary[v]}\n")
          }
        end

        ##
        # Update the global var list (text box)
        #
        def update_global_var_list(gv_ary)
          i=0
          @table_gvar.setTableSize(gv_ary.size,2)
          gv_ary.keys.sort.each { |v|
            if (name = gv_alias(v))
              @table_gvar.setItemText( i, 0, "#{v} (#{name})")
            else
              @table_gvar.setItemText( i, 0, "#{v}")
            end
            @table_gvar.setItemText( i, 1, "#{gv_ary[v]}")
            @table_gvar.getItem( i, 0).justify = 0x00004000 #left
            @table_gvar.getItem( i, 1).justify = 0x00004000 #left
            i += 1
          }
          @table_gvar.setColumnWidth(1,@table_gvar.width - @table_gvar.getColumnWidth(0))
        end

        ##
        # Update the thread list (combobox)
        #
        def update_thread_list(th_list)
          @cbox_thread.clearItems
          idx = 0
          th_list.each do |t|
            @cbox_thread.appendItem(@slot.manager.format_thread(t))
            @cbox_thread.setItemData(idx, t)
            idx += 1
            # if this is the current thread show it in the widget
            @cbox_thread.setCurrentItem(t[0]-1) if t[2]
          end
        end
  
        ##
        # Update the frame list (combobox)
        #
        def update_frame_list(fr_list)
          return unless @slot.manager
          @cbox_frame.clearItems
          idx = 0
          fr_list.each do |f|
            @cbox_frame.appendItem(@slot.manager.format_frame(f))
            @cbox_frame.setItemData(idx, f)
            idx += 1
            # if this is the current frame show it in the widget
            @cbox_frame.setCurrentItem(f[0]-1) if f[4]
          end
        end

        ##
        # Send a list of all watch point currently listed in the GUI
        #
        def list_watchpoints
          (0..@watch_list.getNumItems-1).collect { |i| @watch_list.getItemText(i) }
        end

        ##
        # 
        ##
        # The debugging session has just been started. Change
        # the UI accordingly
        #
        def start
          # clear the console frame
          @console.text = ""
          #TODO: to be done
          # grey out non usable icons
          # in threads and frames tabs say the application has stopped
        end
  
        ##
        # Terminate the remote debuggee process
        #
        def stop
          #TODO:
          # in threads and frames tabs say the application has stopped 
	  @slot.manager.pause if @slot.manager
          @slot.manager.send_command('CLOSE')
        end

        ##
        # Terminate the remote debuggee process and close the
        # debugger dockpane
        #
        def close
          #@slot.manager.send_command('CLOSE') if @slot.manager.running?
	  stop
          my_hide()
        end
        

        ##
        # monitor the debuggee stderr and print any incoming text
        # to the debugger text console
        #
        def attach_stderr(fh)
          @stderr = fh
        
          # temporary variable to test various approaches
          if !VIA_FOX
            # Works on Linux but it freezes FR on Win32, why?
            @th_stderr = Thread.new do
              loop do
                begin
                  text = fh.sysread(100000)
                  print_stderr(text)
                rescue EOFError
                  detach_stderr(fh)
                end
              end
            end
        
          else
            # Should work with FXRuby (lyle said it does) but doesn't run on 1.7.3
            getApp().addInput(fh, INPUT_READ|INPUT_EXCEPT) do |sender, sel, ptr|
              case FXSELTYPE(sel)
              when SEL_IO_READ
                begin
                  text = fh.sysread(100000)
                  print_stderr(text)
                rescue EOFError
                  detach_stderr(fh)
                end
              when SEL_IO_EXCEPT
                puts 'onPipeExcept'
              end
            end
          end
        end
        
        ##
        # monitor the debuggee stdout and print any incoming text
        # to the debugger text console
        #
        def attach_stdout(fh)
          @stdout = fh
          if !VIA_FOX
            #TODO: Works on Linux but it freezes FR on Win32, why? It apparently
            # has something to do with the fact that there is FOX GUI thread running
            # as well because the same kind of thread in a simple ruby program works ok.
            @th_stdout = Thread.new do
              loop do
                begin
                  text = fh.sysread(5000)
                  print_stdout(text)
                rescue EOFError
                  detach_stdout(fh)
                end
              end
            end
        
          else
            # Can't use FOX addInput because it doesn't work on Win32 with Ruby IO objects
            getApp().addInput(fh, INPUT_READ|INPUT_EXCEPT) do |sender, sel, ptr|
              case FXSELTYPE(sel)
              when SEL_IO_READ
                begin
                  text = fh.sysread(5000)
                  print_stdout(text)
                rescue EOFError
                  detach_stdout(fh)
                end
              when SEL_IO_EXCEPT
                puts 'onPipeExcept'
              end
            end
          end
        end
  
        ##
        # attach stdin of debugged process to the renderer
        #
        def attach_stdin(fh)
          @stdin = fh
        end
    
        ##
        # Detach the stderr input from the text console
        #
        def detach_stderr(fh)
          if fh
            if !VIA_FOX
              @th_stderr.kill
            else
              getApp().removeInput(fh, INPUT_READ|INPUT_EXCEPT)
            end
            @stderr = nil
          end
        end
  
        ##
        # Detach the stdout input from the text console
        #
        def detach_stdout(fh)
          if fh
            if !VIA_FOX
              @th_stdout.kill
            else
              getApp().removeInput(fh, INPUT_READ|INPUT_EXCEPT)
            end
            @stdout = nil
          end
        end
  
        ##
        # Detach the stdin from the text console
        #
        def detach_stdin(fh)
          # @stdin should be freed automatically when pipe is closed
          # but just in case
          @stdin = nil
        end
   
        ##
        # print debuggee stderr to text console
        #
        def print_stderr(text)
          @console.appendStyledText(text, 2)
          @console.bottomLine = @console.length
        end
  
        ##
        # print debuggee stderr to text console
        #
        def print_stdout(text)
          @console.appendStyledText(text, 1)
          @console.bottomLine = @console.length
        end

        ##
        # print debuggee stderr to text console
        #
        def print_eval(text)
          @console.appendStyledText(text, 4)
          @console.bottomLine = @console.length
        end
  
        ##
        # Return the FOX FXApp global variable
        #
        def getApp
          @plugin['/system/ui/fox/FXApp'].data
        end

        ##
        # Show debugger configuration dialog box
        #
        def show_config
          #getApp.beginWaitCursor
          configurator_actions = @plugin['/system/ui/current/Configurator/actions']
          configurator_actions['start'].invoke()
          dbg_config_slot = @plugin['configurator/Debugger']
          configurator_actions['show_pane'].invoke(dbg_config_slot)
          #getApp.endWaitCursor
        end
  
        def onCmdStart(sender, sel, ptr)
          return 0 unless @slot.manager
          @slot.manager.start
          return 1
        end
  
        def onUpdStart(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, !@slot.manager.running?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdStop(sender, sel, ptr)
          stop()
          return 1
        end
  
        def onUpdStop(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdClose(sender, sel, ptr)
          close()
          return 1
        end
  
        def onCmdStepOver(sender, sel, ptr)
          @slot.manager.send_command('next') if @slot.manager
          return 1
        end
  
        def onUpdStepOver(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running? && @slot.manager.paused?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdStepIn(sender, sel, ptr)
          @slot.manager.send_command('step') if @slot.manager
          return 1
        end
  
        def onUpdStepIn(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running? && @slot.manager.paused?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdStepOut(sender, sel, ptr)
          @slot.manager.send_command('finish') if @slot.manager
          return 1
        end
  
        def onUpdStepOut(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running? && @slot.manager.paused?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdResume(sender, sel, ptr)
          @slot.manager.resume if @slot.manager
          return 1
        end
  
        def onUpdResume(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running? && @slot.manager.paused?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdPause(sender, sel, ptr)
          @slot.manager.pause if @slot.manager
          return 1
        end
  
        def onUpdPause(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running? && !@slot.manager.paused?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdRunToCursor(sender, sel, ptr)
          @slot.manager.run_to_cursor
          return 1
        end
  
        def onUpdRunToCursor(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running? && @slot.manager.paused?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdViewBreakpoints(sender, sel, ptr)
          #TODO: to be done
          return 1
        end
  
        def onUpdViewBreakpoints(sender, sel, ptr)
          return 1
        end
  
        def onCmdShowExecPoint(sender, sel, ptr)
          @slot.manager.show_exec_point if @slot.manager
          return 1
        end
  
        def onUpdShowExecPoint(sender, sel, ptr)
          if @slot.manager
            update_state(sender,sel,ptr, @slot.manager.running?)
          else
            update_state(sender,sel,ptr, false)
          end
          return 1
        end
  
        def onCmdHelp(sender, sel, ptr)
          #TODO: to be done
          @slot.manager.show_thread_list if @slot.manager
          return 1
        end
  
        def onKeyPTextConsole(sender, sel, ptr)
          #HACK: this is a quick hack to leave it FOX to manage all
          # special characters (RETURN, BS, DEL, Arrow keys,....).
          # Can we do better than that?
          if ( ptr.text.length>0 && ptr.text[0] >= 32)
            @console.appendStyledText(ptr.text, 3)
            ret = 1
          else
            # returning 0 makes the FXText widget handle the char itself
            ret = 0
          end

          # send user input to remote process unless pipe is closed.
          unless @stdin.nil? || @stdin.closed?
            if (ptr.text[0] == 13)
              @stdin.syswrite("\n")
            else
              @stdin.syswrite(ptr.text)
            end
          end

          return ret
        end
  
        def onCmdThreadSelect(sender, sel, ptr)
          # Get the index of the selected thread
          idx = sender.currentItem
          @slot.manager.select_thread(sender.getItemData(idx)) if @slot.manager
          return 1
        end
  
        def onCmdFrameSelect(sender, sel, ptr)
          # Get the index of the selected frame
          idx = sender.currentItem
          @slot.manager.select_frame(sender.getItemData(idx)) if @slot.manager
          return 1
        end
          
        def onCmdEvalExpr(sender, sel, ptr)
          # Get the expression from the text field and show the
          # output result 
          expr = sender.text
          string_val = @slot.manager.eval_expr(expr) if @slot.manager
          print_eval("\neval> #{expr}\n#{string_val}\n")
          sender.setText('')
          return 1
        end

        def onCmdAddWatchPoint(sender, sel, ptr)
          # Get the watch point expression from the text field
          expr = @watch_tf.text
          item = FXListItem.new(expr)
          @watch_list.appendItem(item)
          gui_idx = @watch_list.getNumItems-1
          @slot.manager.add_watchpoint(expr,gui_idx) if @slot.manager
          #item.setData(idx)
          @watch_tf.setText('')
          return 1
        end

        def onCmdDeleteWatchPoint(sender, sel, ptr)
          # Delete the selected watch point
          current = @watch_list.getCurrentItem
          return if current < 0
          expr = @watch_list.getItemText(current)
          done = @slot.manager.delete_watchpoint(expr,current) if @slot.manager
          @watch_list.removeItem(current)
          return 1
        end

        def update_state(sender, sel, ptr, cond)
          if cond
            sender.handle(self, MKUINT(FXWindow::ID_ENABLE, SEL_COMMAND), nil)
          else
            sender.handle(self, MKUINT(FXWindow::ID_DISABLE, SEL_COMMAND), nil)
          end
        end

        private

        @@gv_aliases = nil

        def gv_alias(gvar)
          if @@gv_aliases.nil?
            # Create an hash key of aliases for $... English names
            english_file = nil
            $:.each do |d| 
              english_file = File.join(d,"English.rb")
              break if File.exist?(english_file)
            end
        
            if english_file
              @@gv_aliases = Hash.new
              IO.foreach(english_file) do |line|
                @@gv_aliases[$2] = $1 if (line =~ /^\s*alias\s+(\$[^\s]*)\s+(\$[^\s]*)/ )
              end
            end
          end
          @@gv_aliases[gvar]
        end

  
      end  # class Renderer
  
    end  # module DebuggerRenderFox
  end # FoxRenderer
end  # module FreeRIDE

