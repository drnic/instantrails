# Purpose: Setup and initialize the core gui interfaces of the editpane
#
# $Id: editpane.rb,v 1.46 2005/12/16 11:11:40 jonathanm Exp $
#
# Authors:  Curt Hibbs <curt@hibbs.com>
#           Laurent Julliard <laurent AT moldus DOT org>
#           Richard Kilmer <rich AT infoether DOT com>
# Contributors: 
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2001 Curt Hibbs. All rights reserved.
# Copyright (c) 2002-2003 Laurent Julliard. All rights reserved.
# Copyright (c) 2002-2003 Rich Kilmer. All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end
require 'fox12/responder'
require 'fox12/colors'
require 'rubyide_fox_gui/fxscintilla/scintilla'
require 'rubyide_fox_gui/editpane_configurator'
require 'rubyide_gui/code_template'

module FreeRIDE
  module FoxRenderer
    
    include Fox
    include FreeRIDE::Objects

    ##
    # This is the module that renders ediutpanes using
    # FXScintilla.
    #
    class EditPane
      include Fox
      ICON_PATH = "/system/ui/icons/EditPane"
      
      extend FreeBASE::StandardPlugin

      def EditPane.start(plugin)
        edit_book_slot = plugin["/system/ui/fox/editBook"]
        
        component_slot = plugin["/system/ui/components/EditPane"]

        # Subscribe to the editpane slot to render any newly created edit pane
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            if (edit_book_slot.data == nil) 
              # create (only once) a TabBook in which all editor windows will appear 
              contentFrame = plugin["/system/ui/fox/contentFrame"].data
              tb = FXTabBook.new(contentFrame, nil, 0,LAYOUT_FILL_X|LAYOUT_FILL_Y)
              tb.create
              edit_book_slot.data = tb
              # catch selected tabitems on the tabbook (scn is the panel number 0,1,2...)
              tb.connect(SEL_COMMAND) do |sender, sel, scn|
                editpane_slot = tb.childAtIndex(2*scn).userData
                editpane_slot.manager.make_current
              end
            end
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

        # Create the Goto Line command
        cmd_mgr = plugin["/system/ui/commands"].manager
        cmdg = cmd_mgr.add("EditPane/GotoLine", "Line...") do |cmd_slot|
          GotoLineDialog.new(plugin)
        end
        plugin["/system/ui/keys"].manager.bind("EditPane/GotoLine", :ctrl, :G)

        # Create the Find EditPane command
        cmdf = cmd_mgr.add("EditPane/Find", "&Find...") do |cmd_slot|
          sd = FindDialog.new(plugin)
          sd.execute
        end
        plugin["/system/ui/keys"].manager.bind("EditPane/Find", :ctrl, :F)

        # Create the Find/Replace command
        cmdr = cmd_mgr.add("EditPane/Replace", "&Replace...") do |cmd_slot|
          rd = ReplaceDialog.new(plugin)
          rd.execute
        end
        plugin["/system/ui/keys"].manager.bind("EditPane/Replace", :ctrl, :R)

        # Create the Find Next command
        cmdfn = cmd_mgr.add("EditPane/FindNext", "Find &next") do |cmd_slot|
          fd = FindDialog.new(plugin)
          fd.onCmdNext(nil,nil,nil)
        end
        plugin["/system/ui/keys"].manager.bind("EditPane/FindNext", :F3)
       
        # Create the Find Prev command
        cmdfp = cmd_mgr.add("EditPane/FindPrev", "Find pre&vious") do |cmd_slot|
          fd = FindDialog.new(plugin)
          fd.onCmdPrev(nil,nil,nil)
        end
        plugin["/system/ui/keys"].manager.bind("EditPane/FindPrev", :shift, :F3)

        # Create the Code Templates... command
        cmdct = cmd_mgr.add("EditPane/CodeTemplates", "Code &Templates...") do |cmd_slot|
        ep_slot = plugin['/system/ui/current/EditPane']
          ep_slot.manager.code_completion()
        end
        plugin["/system/ui/keys"].manager.bind("EditPane/CodeTemplates", :ctrl, :J)

        # Create the Code Templates... command
        #cmdca = cmd_mgr.add("EditPane/CodeAssist", "Code &Assist...") do |cmd_slot|
        #  ep_slot = plugin['/system/ui/current/EditPane']
        #  ep_slot.manager.code_assist()
        #end
        #plugin["/system/ui/keys"].manager.bind("EditPane/CodeAssist", :ctrl, :K)
       
        # Command availability subject to same behavior for all three
        [cmdg,cmdf,cmdr,cmdfn,cmdfp,cmdct].each do |cmd|
          cmd.availability = plugin['/system/ui/current'].has_child?('EditPane')
          cmd.manage_availability do |command|
            plugin['/system/ui/current'].subscribe do |event, slot|
              if slot.name=="EditPane"
                case event
                when :notify_slot_link
                  command.availability=true
                when :notify_slot_unlink
                  command.availability=false
                end
              end
            end
          end
        end

        # Insert the "goto line..." menu item in the Goto menu
        gotomenu = plugin["/system/ui/components/MenuPane/Goto_menu"].manager
        gotomenu.add_command("EditPane/GotoLine")

        # Insert the "Find..." and "Replace..." menu item in the Search menu
        searchmenu = plugin["/system/ui/components/MenuPane/Search_menu"].manager
        searchmenu.add_command("EditPane/Find")
        searchmenu.add_command("EditPane/Replace")
        searchmenu.add_command("EditPane/FindNext")
        searchmenu.add_command("EditPane/FindPrev")

        # Insert the "Code Templates..." menu item in the Edit menu
        editmenu = plugin["/system/ui/components/MenuPane/Edit_menu"].manager
        editmenu.add_command("EditPane/CodeTemplates")
        #editmenu.add_command("EditPane/CodeAssist")
	
        # Initialize configurator UI for the editor - Must be done
        # before any editpane is created
        EditPaneConfiguratorRenderer.new(plugin)

        # Update the status of some checked menu items
        cmd_mgr.command('App/View/Whitespace').checked = plugin.properties['white_space']
        cmd_mgr.command('App/View/EndOfLine').checked =  plugin.properties['eol']
        cmd_mgr.command('App/View/LineNumbers').checked =  plugin.properties['line_numbers']
 
        # Restore files edited in the previous session
        component_slot.each_slot do |slot| 
          slot.notify(:notify_slot_add)
          slot.manager.load_file(slot.data)
          slot.notify(:notify_data_set)
          slot.manager.make_current
        end

        # Also load any file appearing on the command line
        ARGV.each do |filename|
          # see if it has already been loaded
          loaded = false
          plugin['/system/ui/components/EditPane'].each_slot do |ep_slot|
            if ep_slot.data == filename
              loaded = true
              break
            end
          end
	  
          unless loaded
            ep_slot = plugin['/system/ui/components/EditPane'].manager.add
            ep_slot.manager.load_file(filename)
          end
        end

        # Make the first editpane the current one
        component_slot.each_slot do |slot| 
          slot.manager.make_current
          break
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
          @app = plugin['/system/ui/fox/FXApp'].data
          @icons = plugin[ICON_PATH]
          @edit_book = plugin["/system/ui/fox/editBook"].data
          @tab = FXTabItem.new(@edit_book, slot.data, nil, TAB_TOP_NORMAL)
          @tab.iconPosition = ICON_AFTER_TEXT
          @frame = FXHorizontalFrame.new(@edit_book, FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @scintilla = FXScintilla.new(@frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @tab.create
          @tab.connect(SEL_FOCUSIN) {@scintilla.setFocus}
          @frame.create
          @scintilla.create
          # attach the slot to the 2 tabitem widget and the renderer to the
          # scintilla controller s so that they both know to which higher
          # level object they belong to
          @tab.userData = @slot
          @scintilla.userData = self
          @controller = ScintillaController.new(@scintilla)
          @scintilla.connect(SEL_COMMAND) do |sender, sel, scn|
            @controller.handle_notification(scn.nmhdr.idFrom, scn.nmhdr.code, scn)
          end
          @controller.setup
          setup_actions

          slot.subscribe do |event, slot|
            update(event) if ((event == :refresh) || (event == :notify_data_set))
          end

          # Apply user-defined editor preferences
          plugin['/plugins/rubyide_fox_gui-editpane/configurator'].manager.apply_all_config(@slot)

          @plugin.log_info << "EditPane created"
        end
        
        def update(event)
          if (event == :notify_data_set)
            # the data slot holds the file name so update the tabItem 
            if (@slot.data) 
              @tab.text = File.basename(@slot.data)
            else
              @tab.text = 'Untitled'
            end
          end
        end
        
        def setup_actions
          bind_action("filename", :filename)
          bind_action("load_file", :load_file)
          bind_action("make_current", :make_current)
          bind_action("close", :close)
          bind_action("save", :save)
          bind_action("neighbor", :neighbor)
          bind_action("modified", :modified?)
          bind_action("undo", :undo)
          bind_action("redo", :redo_cmd)
          bind_action("cut", :cut)
          bind_action("copy", :copy)
          bind_action("paste", :paste)
          bind_action("show_errorline", :show_errorline)
          bind_action("clear_errorline", :clear_errorline)
          bind_action("show_debugline", :show_debugline)
          bind_action("clear_debugline", :clear_debugline)
          bind_action("get_cursor_line", :cursor_line)
          bind_action("set_cursor_line", :set_cursor_line)
          bind_action("get_text", :get_text)
          bind_action("get_text_length", :text_length)
          bind_action("help_lookup", :help_lookup)
          bind_action("code_completion", :code_completion)
          bind_action("get_ext_object", :get_ext_object)
          bind_action("is_whitespace_visible", :is_whitespace_visible?)
          bind_action("whitespace_visible", :whitespace_visible=)
          bind_action("is_eol_visible", :is_eol_visible?)
          bind_action("eol_visible", :eol_visible=)
          bind_action("are_linenumbers_visible", :are_linenumbers_visible?)
          bind_action("linenumbers_visible", :linenumbers_visible=)
          bind_action("are_indentation_guides_visible", :are_indentation_guides_visible?)
          bind_action("indentation_guides_visible", :indentation_guides_visible=)
          bind_action("set_caret_period", :caret_period=)
          bind_action("get_caret_period", :caret_period)
          bind_action("set_caret_fore", :caret_fore=)
          bind_action("set_caret_width", :caret_width=)
          bind_action("get_wrap_mode", :wrap_mode)
          bind_action("set_code_folding", :code_folding=)
          bind_action("get_code_folding", :code_folding)
          bind_action("get_editor_font", :editor_font=)
          bind_action("set_editor_font", :editor_font)
          bind_action("set_style", :set_style)
          bind_action("set_style_clear_all", :set_style_clear_all)
          bind_action("get_project", :get_project)
          bind_action("set_project", :project=)
        end
        
        def bind_action(name, meth)
          @slot["actions/#{name}"].set_proc method(meth)
        end
        
        ### Commands ###
        
        def get_project
          @project
        end
        
        def project=(prj)
          @project = prj
        end
        
        def get_ext_object
          @controller.model
        end
        
        def filename
          @slot.manager.filename
        end
        
        def load_file(filename, breakpoints=nil)
          loaded = false
          begin
            @app.beginWaitCursor()
            begin
              @controller.open(filename)
            rescue
              cmd_mgr = @plugin["/system/ui/commands"].manager
              cmd_mgr.command('App/Services/MessageBox').invoke("File Load Error!",$!.to_s.wrap(60))
            else
              if breakpoints
                breakpoints.each {|line| @controller.toggle_breakpoint(line-1, false)}
              end
              loaded = true
            end
          ensure
            @app.endWaitCursor()
          end
          return loaded
        end
        
        def make_current
          index = @edit_book.indexOfChild(@tab)
          @edit_book.setCurrent(index/2)
          @edit_book.childAtIndex(index+1).setFocus()
          @scintilla.setFocus()
        end
        
        def close
          # FIXME? : how to delete an item in the tabbook? I'm not sure
          # for the moment I remove child 2*N+1 first (the scintilla pane) and then
          # the 2*N (the tabitem) second. It works.
          @tab.hide()
          @frame.removeChild(@scintilla)
          @edit_book.removeChild(@frame)
          @edit_book.removeChild(@tab)
          @tab = nil
          @frame = nil
          @tab = nil
        end
        
        def save(filename)
          begin
            @app.beginWaitCursor()
            begin
              @controller.save(filename)
            rescue
              cmd_mgr = @plugin["/system/ui/commands"].manager
              cmd_mgr.command('App/Services/MessageBox').invoke("File Save Error!",$!.to_s.wrap(60))
            end
          ensure
            @app.endWaitCursor()
          end
        end
        
        def neighbor
          tab_index = @edit_book.indexOfChild(@tab)
          if (tab_index == 0)
            if @edit_book.numChildren > 2
              tab_index += 2
            else
              return nil
            end
          else
            tab_index -= 2
          end
          @edit_book.childAtIndex(tab_index).userData
        end
        
        def modified?
          @controller.modified?
        end

        def undo
          @controller.undo
        end
        
        def redo_cmd
          @controller.redo
        end
        
        def cut
          @controller.cut
        end
        
        def is_eol_visible?
          @controller.is_eol_visible?
        end
        
        def eol_visible=(value)
          @controller.eol_visible = value
        end
        
        def is_whitespace_visible?
          @controller.is_whitespace_visible?
        end
        
        def whitespace_visible=(value)
          @controller.whitespace_visible=value
        end
        
        def are_linenumbers_visible?
          @controller.are_linenumbers_visible?
        end
        
        def linenumbers_visible=(value)
          @controller.linenumbers_visible=value
        end
      
        def are_indentation_guides_visible?
          @controller.are_indentation_guides_visible?
        end
        
        def indentation_guides_visible=(value)
          @controller.indentation_guides_visible=value
        end   
     
        def is_eol_visible?
          @controller.is_eol_visible?
        end
        
        def caret_period
          @controller.caret_period
        end
     
        def caret_period=(msec)
          @controller.caret_period = msec
        end

        def caret_fore
          self.get_ext_object.get_caret_fore
        end
     
        def caret_fore=(rgba)
          self.get_ext_object.set_caret_fore(rgba&0xFFFFFF)
        end       

        def caret_width
          self.get_ext_object.get_caret_width
        end
     
        def caret_width=(width)
          self.get_ext_object.set_caret_width(width)
        end       
           
        def wrap_mode
          @controller.wrap_mode
        end        

        def wrap_mode=(status)
          @controller.wrap_mode = status
        end
     
        def code_folding
          @controller.code_folding
        end        

        def code_folding=(status)
          @controller.code_folding = status
        end

        def editor_font
          @controller.editor_font
        end        

        def editor_font=(font)
          @controller.editor_font = font
        end

        def set_style(style_name, style)
          @controller.set_style(style_name,style)
        end

        def set_style_clear_all
          @controller.set_style_clear_all
        end
           
        def copy
          @controller.copy
        end
        
        def paste
          @controller.paste
        end
        
        def show_errorline(line)
          @controller.show_errorline(line)
        end
        
        def clear_errorline
          @controller.show_errorline(nil)
        end

        def show_debugline(line)
          @controller.show_debugline(line)
        end
        
        def clear_debugline
          @controller.show_debugline(nil)
        end
        
        def cursor_line
          @controller.cursor_line+1
        end
        
        def set_cursor_line(line)
          @controller.cursor_line = line-1
        end

        def get_text
          @controller.get_text
        end

        def text_length
          @controller.text_length
        end

        def help_lookup
          @controller.help_lookup
        end

        ##
        # called from the scintilla controller whenever the modified
        # status flag is updated
        #
        #  
        #  Return:: [Boolean] true if it debugger paused
        #
        def modified=(flag)
          if flag
            icon = @icons['modified'].data
            @tab.icon = icon
          else
            @tab.setIcon(nil)
          end
        end
        
        ##
        # add a breakpoint on the line
        # called from the scintilla controller
        #
        def add_breakpoint(line)
          @slot.manager.add_breakpoint(line)
        end
        
        ##
        # delete a breakpoint on the line
        # called from the scintilla controller
        #
        def delete_breakpoint(line)
          @slot.manager.delete_breakpoint(line) 
        end

        ##
        # Get the help lookup context from the Scintills editor
        # It returns the word at or next to cursor plus what's before and 
        # what's after on the line
	#
        def help_lookup()
          @controller.help_lookup() 
        end

        ##
        # forward the request for code completion 
        # to the Ruby Doc plugin via the editpane mgr
        #
        def code_completion

          # Determine where to place the code template
          # dialog box on the screen (right below the cursor)
          posx = get_ext_object.point_x_from_position(get_ext_object.get_current_pos)
          posy = get_ext_object.point_y_from_position(get_ext_object.get_current_pos)
          posy += get_ext_object.text_height(get_ext_object.line_from_position(get_ext_object.get_current_pos))
          #puts posx,posy
      
          posx,posy = @scintilla.translateCoordinatesTo(plugin["/system/ui/fox/FXMainWindow"].data, posx, posy)
          #puts posx,posy
      
          mainx = plugin["/system/ui/fox/FXMainWindow"].data.x
          mainy = plugin["/system/ui/fox/FXMainWindow"].data.y
      
          # let the user chose the code template
          ctd = CTemplateDialog.new(plugin, mainx+posx, mainy+posy, FreeRIDE::Objects::CODE_TEMPLATES["Ruby"])
          ctd.execute(PLACEMENT_VISIBLE)
      
          # insert the code template if any selected
          if ctemp = ctd.code_template
      
            # expand selected template
            selection = get_ext_object.get_sel_text.chop #chop the trailing \0
            if selection.empty?
              line_cursor = get_ext_object.line_from_position(get_ext_object.get_current_pos)
              line_indent = get_ext_object.get_line_indentation(line_cursor)
              insert_pos = get_ext_object.position_from_line(line_cursor)
            else
              line_selection_start = get_ext_object.line_from_position(get_ext_object.get_selection_start)
              line_indent = get_ext_object.get_line_indentation(line_selection_start)
              insert_pos = get_ext_object.position_from_line(line_selection_start)
            end
            indent = get_ext_object.get_indent()
            text, cursor_offset, selection_used = ctemp.expand(selection,Hash.new, line_indent, indent)
      
            #insert it
            if selection_used
              get_ext_object.cut
            end
            get_ext_object.insert_text(insert_pos, text)
            get_ext_object.set_save_point
      
            #place the cursor where it is supposed to be 
            get_ext_object.goto_pos(insert_pos+cursor_offset)
      
          end
        end

      end  # class Renderer
      

      class CTemplateDialog < FXDialogBox
        include Fox
        include Responder
      
        MAX_VISIBLE = 15

        ID_CTEMP_LIST,
        ID_LAST = enum(FXDialogBox::ID_LAST, 2)

        def initialize(plugin, x, y, templates)
          @plugin = plugin
          @templates = templates
          owner = plugin["/system/ui/fox/FXMainWindow"].data
          @name = ""
      
          FXMAPFUNC(SEL_COMMAND, ID_CTEMP_LIST, :onCmdCTempChosen)
          FXMAPFUNC(SEL_KEYPRESS, ID_CTEMP_LIST, :onKeyPress)
          FXMAPFUNC(SEL_FOCUSOUT, 0,:onCmdCancel)
          FXMAPFUNC(SEL_CLICKED, ID_CTEMP_LIST, :onClicked)
      
          super(owner,"Code Templates", DECOR_STRETCHABLE|DECOR_SHRINKABLE,0,0,0,0,0,0,0,0)
                @vfrm = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE,0,0,0,0,0,0,0,0,0,0)
                vsfrm1 = FXVerticalFrame.new(@vfrm, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_LINE,0,0,0,0,0,0,0,0,0,0)
          @list = FXList.new(vsfrm1, self, ID_CTEMP_LIST, LIST_SINGLESELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y|HSCROLLING_OFF)
          @list.font = FXFont.new(plugin["/system/ui/fox/FXApp"].data, "courier", 10, FONTWEIGHT_NORMAL, FONTSLANT_REGULAR, FONTENCODING_DEFAULT, FONTSETWIDTH_DONTCARE, FONTPITCH_FIXED)
          @list.backColor = FXColor::FloralWhite
                vsfrm2 = FXVerticalFrame.new(@vfrm, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_LINE,0,0,0,0,0,0,0,0,0,0)
          @tfrm = FXText.new(vsfrm2, nil, 0, TEXT_READONLY|LAYOUT_FILL_X|LAYOUT_FILL_Y|VSCROLLING_OFF|HSCROLLING_OFF)
          @tfrm.font = FXFont.new(plugin["/system/ui/fox/FXApp"].data, "courier", 10, FONTWEIGHT_NORMAL, FONTSLANT_REGULAR, FONTENCODING_DEFAULT, FONTSETWIDTH_DONTCARE, FONTPITCH_FIXED)
          @tfrm.backColor = FXColor::AliceBlue
          self.create
      
          # Fill out the list
          build_list()
      
          self.move(x,y)
      
          # make sure the cursor is inside the dialog box to avoid
          # spurious FOCUS OUT when resisizing the dialog box
          self.setCursorPosition(x+40,y+2)
      
        end
      
        def code_template
          @name.empty? ? nil : @templates[@name]
        end
      
        def build_list(pattern="")
          cts = []
          @templates.each_pair do |name, ctemp|
            matching = (pattern.empty? || name =~ /^#{pattern}/)
            cts << name if matching
          end
          unless cts.empty?
            @list.clearItems
            cts.sort.each do |name|
              string = sprintf("%-10s%s",name,@templates[name].description)
              item = FXListItem.new(string)
              idx = @list.appendItem(string)
              @list.setItemData(idx, name)
            end
            @list.numVisible = [@list.numItems, MAX_VISIBLE].min
            #@list.numVisible = cts.size
            @list.selectItem(0)
            @list.currentItem = 0
            @tfrm.text = @templates[@list.getItemData(0)].expand()[0]
            @list.setFocus
      
            self.resize(self.getDefaultWidth(),self.getDefaultHeight())
          end
          return !cts.empty?
        end
      
        def onKeyPress(sender, sel, event)
          rebuild = false
          if (event.code >= KEY_A && event.code <= KEY_Z) ||
              (event.code >= KEY_a && event.code <= KEY_z) ||
              (event.code >= KEY_0 && event.code <= KEY_9)
            #puts "#{event.code}"
            @name << event.code.chr
            @name.chop! unless build_list(@name)
          elsif event.code == KEY_BackSpace
            @name.chop!
            build_list(@name)
          elsif event.code == KEY_Escape
            @name = ""
            onCmdCancel(self,nil,nil)
          elsif event.code == KEY_Return || event.code == KEY_KP_Enter
            onCmdCTempChosen(self,nil,nil)
          elsif event.code == KEY_Down
            if @list.currentItem == @list.numItems-1
              @list.currentItem = 0
              @list.selectItem(0)
            else
              nxt = @list.currentItem.succ
              @list.currentItem = nxt
              @list.selectItem(nxt)
            end
          elsif event.code == KEY_Up
            if @list.currentItem == 0
              last = @list.numItems-1
              @list.currentItem = last
              @list.selectItem(last)
            else
              prev = @list.currentItem - 1
              @list.currentItem = prev
              @list.selectItem(prev)
            end
          end
          # update template text view
          @tfrm.text = text = @templates[@list.getItemData(@list.currentItem)].expand()[0]
          @list.numVisible = [@list.numItems, MAX_VISIBLE].min
          @list.makeItemVisible(@list.currentItem)
          #@list.numVisible = @list.numItems
          #@tfrm.visibleRows = 10
          self.resize(self.getDefaultWidth(),self.getDefaultHeight())
      
          return 1
        end
      
        def onCmdCancel(sender, sel, ptr)
          self.handle(self,MKUINT(FXDialogBox::ID_CANCEL,SEL_COMMAND),nil)
          return 1
        end
      
        def onCmdCTempChosen(sender, sel, ptr)
          @name = @list.getItemData(@list.currentItem)
          #puts "-- #{@name}"
          self.handle(self,MKUINT(FXDialogBox::ID_ACCEPT,SEL_COMMAND),nil)
          return 1
        end
      
        def onClicked(sender,sel,ptr)
          # if the cursor is not on an list item then give up
          onCmdCTempChosen(sender, sel, ptr)
        end

      end

      class GotoLineDialog < FXDialogBox

        include Fox
        def initialize(plugin)
          @plugin = plugin
          owner = plugin["/system/ui/fox/FXMainWindow"].data
          
          # Invoke base class initialize function first
          super(owner, "Goto Line", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE)
          h_frm = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
          FXLabel.new(h_frm, "Line: ", nil, JUSTIFY_LEFT|LAYOUT_CENTER_Y)
          line_tf = FXTextField.new(h_frm, 12, nil, 0, (FRAME_SUNKEN|
                  LAYOUT_FILL_X|LAYOUT_CENTER_Y|LAYOUT_FILL_COLUMN))
          line_tf.connect(SEL_COMMAND, method(:onCmdFetchLine))
          line_tf.setFocus
          self.connect(SEL_CLOSE) { self.destroy }
          self.create
          self.show(PLACEMENT_OWNER)
        end
        
        def onCmdFetchLine(sender, sel, ptr)
          line = sender.text.to_i
          ep_slot = @plugin['/system/ui/current/EditPane']
          ep_slot['actions/set_cursor_line'].invoke(line) if line > 0
          # return focus to the edit pane when the dialog box closes
          ep_slot['actions/make_current'].invoke()
          self.destroy
        end

      end # class GotoLineDialog


      class ReplaceDialog < FXDialogBox

        include Fox
        include Responder

        attr_accessor :accept, :every, :inselection, :replacelabel, :replacebox, :searchlast, :searchnext

        HORZ_PAD    = 10
        VERT_PAD    = 3

        ID_REPLACE,
        ID_NEXT_MATCH,
        ID_PREV_MATCH,
        ID_SEARCH_TEXT,
        ID_REPLACE_TEXT,
        ID_REPLACE_ALL,
        ID_REPLACE_INSEL,
        ID_MODE_WHOLEWORD,
        ID_MODE_WRAP,
        ID_MODE_MATCHCASE,
        ID_MODE_BACKSLASH,
        ID_MODE_WORDSTART,
        ID_MODE_REGEXP,
        ID_MODE_DIR,
        ID_LAST = enum(FXDialogBox::ID_LAST, 32)
        
        # Search mode flags
        SEARCH_WHOLEWORD   = 0x1
        SEARCH_WRAP        = 0x2
        SEARCH_MATCHCASE   = 0x4
        SEARCH_BACKSLASH   = 0x8
        SEARCH_REGEXP      = 0x10
        SEARCH_REGEXPPOSIX = 0x20
        SEARCH_BACKWARD    = 0x40
        SEARCH_WORDSTART   = 0x80

        # Max number of elements in sear/replace combobox history
        HISTORY_SIZE = 10

        def initialize(plugin)
          @plugin = plugin
          @app = plugin["/system/ui/fox/FXApp"].data
          owner = plugin["/system/ui/fox/FXMainWindow"].data
          ic = nil
          @havefound = false

          FXMAPFUNC(SEL_COMMAND,   ID_REPLACE,           :onCmdReplaceOnce)
          FXMAPFUNC(SEL_COMMAND,   ID_REPLACE_TEXT,      :onCmdSearchText)
          FXMAPFUNC(SEL_COMMAND,   ID_SEARCH_TEXT,       :onCmdSearchText)
          FXMAPFUNC(SEL_COMMAND,   ID_REPLACE_ALL,       :onCmdReplaceAll)
          FXMAPFUNC(SEL_COMMAND,   ID_REPLACE_INSEL,     :onCmdReplaceAll)
          FXMAPFUNC(SEL_COMMAND,   ID_PREV_MATCH,        :onCmdPrev)
          FXMAPFUNC(SEL_COMMAND,   ID_NEXT_MATCH,        :onCmdNext)
          FXMAPFUNC(SEL_COMMAND,   ID_MODE_MATCHCASE,    :onCmdMatchCase)
          FXMAPFUNC(SEL_COMMAND,   ID_MODE_WHOLEWORD,    :onCmdWholeWord)
          FXMAPFUNC(SEL_COMMAND,   ID_MODE_WRAP,         :onCmdWrap)
          FXMAPFUNC(SEL_COMMAND,   ID_MODE_REGEXP,       :onCmdRegexp)
          FXMAPFUNC(SEL_COMMAND,   ID_MODE_WORDSTART,    :onCmdWordStart)
          FXMAPFUNC(SEL_COMMAND,   ID_CANCEL,            :onCmdCancel)

          # Invoke base class initialize function first
          super(owner, getDialogTitle, DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE)
          
          buttons = FXVerticalFrame.new(self, LAYOUT_SIDE_RIGHT|LAYOUT_TOP|PACK_UNIFORM_WIDTH)          
          @searchnext = FXButton.new(buttons,"&Find Next",nil,self,ID_NEXT_MATCH,BUTTON_INITIAL|BUTTON_DEFAULT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_RIGHT,
                                      0,0,0,0,HORZ_PAD,HORZ_PAD,VERT_PAD,VERT_PAD)
          @searchlast = FXButton.new(buttons,"Find &Previous",nil,self,ID_PREV_MATCH,BUTTON_INITIAL|BUTTON_DEFAULT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_RIGHT,
                                      0,0,0,0,HORZ_PAD,HORZ_PAD,VERT_PAD,VERT_PAD)
          @accept = FXButton.new(buttons,"&Replace",nil,self,ID_REPLACE,BUTTON_INITIAL|BUTTON_DEFAULT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_RIGHT,
                                  0,0,0,0,HORZ_PAD,HORZ_PAD,VERT_PAD,VERT_PAD)
          @every = FXButton.new(buttons,"Replace &All",nil,self,ID_REPLACE_ALL,BUTTON_DEFAULT|FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_Y|LAYOUT_RIGHT,
                                0,0,0,0,HORZ_PAD,HORZ_PAD,VERT_PAD,VERT_PAD)
          @inselection = FXButton.new(buttons,"In &Selection",nil,self,ID_REPLACE_INSEL,BUTTON_DEFAULT|FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_Y|LAYOUT_RIGHT,
                                      0,0,0,0,HORZ_PAD,HORZ_PAD,VERT_PAD,VERT_PAD)
          cancel = FXButton.new(buttons,"&Cancel",nil,self,ID_CANCEL,BUTTON_DEFAULT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_RIGHT,
                                0,0,0,0,HORZ_PAD,HORZ_PAD,VERT_PAD,VERT_PAD)
          
          entry = FXVerticalFrame.new(self,LAYOUT_SIDE_LEFT|LAYOUT_TOP|LAYOUT_FILL_X, 0,0,0,0, 0,0,0,0)
          searchlabel = FXLabel.new(entry,"S&earch for:",nil,JUSTIFY_LEFT|ICON_BEFORE_TEXT|LAYOUT_TOP|LAYOUT_LEFT|LAYOUT_FILL_X)
          @searchbox = FXComboBox.new(entry,5,self,ID_SEARCH_TEXT,FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          @searchbox.setNumVisible(5)
          @replacelabel = FXLabel.new(entry,"Replace &with:",nil,LAYOUT_LEFT)
          @replacebox = FXComboBox.new(entry,5,self,ID_REPLACE_TEXT,FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          @replacebox.setNumVisible(5)

          options1 = FXMatrix.new(entry,2, FRAME_NONE|MATRIX_BY_COLUMNS|PACK_UNIFORM_WIDTH|LAYOUT_FILL_Y,0,0,0,0,0,0,0,0,0,0)
          @wholeWordChkBtn = FXCheckButton.new(options1,"Match whole word &only",self,ID_MODE_WHOLEWORD,ICON_BEFORE_TEXT|JUSTIFY_LEFT)
          @wrapChkBtn = FXCheckButton.new(options1,"Wrap aro&und",self,ID_MODE_WRAP,ICON_BEFORE_TEXT|JUSTIFY_LEFT)
          @matchCaseChkBtn = FXCheckButton.new(options1,"&Match case",self,ID_MODE_MATCHCASE,ICON_BEFORE_TEXT|JUSTIFY_LEFT)
          @regExpChkBtn = FXCheckButton.new(options1,"Regular e&xpression",self,ID_MODE_REGEXP,ICON_BEFORE_TEXT|JUSTIFY_LEFT)
          @matchWordStartChkBtn = FXCheckButton.new(options1,"Matc&h at word start",self,ID_MODE_WORDSTART,ICON_BEFORE_TEXT|JUSTIFY_LEFT)

          # Add hot keys
          @searchnext.addHotKey(MKUINT(KEY_f,CONTROLMASK))
          @searchlast.addHotKey(MKUINT(KEY_p,CONTROLMASK))
          searchlast.addHotKey(MKUINT(KEY_b,CONTROLMASK))          
          @accept.addHotKey(MKUINT(KEY_r,CONTROLMASK))
          @every.addHotKey(MKUINT(KEY_a,CONTROLMASK))
          @inselection.addHotKey(MKUINT(KEY_s,CONTROLMASK))
          cancel.addHotKey(MKUINT(KEY_c,CONTROLMASK))
          
          @searchbox.addHotKey(MKUINT(KEY_e,CONTROLMASK))
          @replacebox.addHotKey(MKUINT(KEY_w,CONTROLMASK))
          
          @wholeWordChkBtn.addHotKey(MKUINT(KEY_o,CONTROLMASK))
          @wrapChkBtn.addHotKey(MKUINT(KEY_u,CONTROLMASK))
          @matchCaseChkBtn.addHotKey(MKUINT(KEY_m,CONTROLMASK))
          @regExpChkBtn.addHotKey(MKUINT(KEY_x,CONTROLMASK))
          @matchWordStartChkBtn.addHotKey(MKUINT(KEY_h,CONTROLMASK))

          # restore search and replace text field state and history
          # as well as last search mode
          restoreSettings()

        end
        
        def getDialogTitle
          "Replace Text..."
        end
        
        def execute()
          self.create
          #@searchbox.setFocus
          # Mimic a TAB key pressed because the setFocus doesn't work
          # on FXComboBox (bug!)
          fxevt = FXEvent.new()
          fxevt.code = Fox::KEY_Tab
          fxevt.type = Fox::SEL_KEYPRESS
          @searchbox.handle(self,MKUINT(0, SEL_KEYPRESS),fxevt)
          x = @plugin.properties["findsearch/location/x"]
          y = @plugin.properties["findsearch/location/y"]
          x ||= 1
          y ||= 1

          position(x,y,self.width,self.height)
          if x==1
            show(PLACEMENT_OWNER)
          else
            show
          end
          @app.runModalFor(self)
        end

        def model()
          ep_slot = @plugin['/system/ui/current/EditPane']
          ep_slot['actions/get_ext_object'].invoke()
        end

        ##
        # Prompt a message in the status bar
        #
        def status(msg)
          @plugin['/system/ui/current/StatusBar/actions/prompt'].invoke(msg)
        end

        def replaceText()
          @replacebox.getText()
        end

        def replaceText=(text)
          @replacebox.setText(text)
        end


        def searchText()
          @searchbox.getText()
        end

        def searchText=(text)
          @searchbox.setText(text)
        end

        def searchMode()
          @searchmode
        end

        def searchMode=(mode)
          @searchmode = mode
        end

        def searchBackward? ()
          (self.searchMode&SEARCH_BACKWARD) != 0
        end

        def searchWrap? ()
          (self.searchMode&SEARCH_WRAP) != 0
        end

        def searchWholeWord? ()
          (self.searchMode&SEARCH_WHOLEWORD) != 0
        end

        def searchMatchCase? ()
          (self.searchMode&SEARCH_MATCHCASE) != 0
        end

        def searchRegExp? ()
          (self.searchMode&SEARCH_REGEXP) != 0
        end

        def searchRegExpPosix? ()
          (self.searchMode&SEARCH_REGEXPPOSIX) != 0
        end

        def searchMatchWordStart? ()
          (self.searchMode&SEARCH_WORDSTART) != 0
        end

        def onCmdReplaceOnce(sender, sel, ptr)
          if (@havefound) 
            selstart = model.selection_start
            selend = model.selection_end

            model.target_start = selstart
            model.target_end = selend
            if (self.searchRegExp?)
              lenreplaced = model.replace_target_re(self.replaceText())
            else
              lenreplaced = model.replace_target(self.replaceText())
            end
            model.set_sel(selstart+lenreplaced, selstart)
            @havefound = false
          end
          onCmdNext(sender, sel, ptr)
        end

        def onCmdReplaceAll(sender, sel, ptr)

          if searchText().empty? 
            return 1 
          end
          findlen = searchText().size
          replacelen = replaceText().size

          selstart = startpos = model.selection_start
          selend = endpos = model.selection_end
          if (FXSELID(sel) == ID_REPLACE_INSEL)
            return 1 if selstart == selend
          else
            endpos = model.get_length
            # if wrap mode then replace from beginning to end
            # else from caret to end
            if (self.searchWrap?)
              startpos = 0
            end
          end

          searchflags = (searchWholeWord?   ? Scintilla::SCFIND_WHOLEWORD : 0) |
                        (searchMatchCase?   ? Scintilla::SCFIND_MATCHCASE : 0) |
                        (searchRegExp?      ? Scintilla::SCFIND_REGEXP    : 0) |
                        (searchMatchWordStart? ? Scintilla::SCFIND_WORDSTART : 0)

          model.target_start = startpos
          model.target_end = endpos
          model.search_flags = searchflags
          posfind = model.search_in_target(searchText())

          if ((findlen == 1) && self.searchRegExp? && (self.searchText()[0..0] == '^'))
            # Special case for replace all start of line so it hits the first line
            posfind = startpos;
            model.target_start = startpos
            model.target_end = startpos
          end

          if ((posfind != -1) && (posfind <= endpos))
            lastmatch = posfind
            occurences = 0
            model.begin_undo_action()

            while (posfind != -1)
              lentarget = model.target_end - model.target_start
              movepasteol = 0
              if (lentarget <= 0)
                nextchar = model.char_at(model.target_end)
                if (nextchar=="\r" || nextchar=="\n")
                  # FIXME? shall we test EOL mode and add 2 if it is
                  # SC_EOL_CRLF
                  movepasteol = 1
                end
              end

              lenreplaced = replacelen
              if (self.searchRegExp?)
                lenreplaced = model.replace_target_re(self.replaceText())
              else
                lenreplaced = model.replace_target(self.replaceText())
              end

              # modify end position of the target to reflect the last change
              endpos += lenreplaced - lentarget
              lastmatch = posfind + lenreplaced + movepasteol
              if (lastmatch >= endpos)
                # run off the endof the document with an empty match
                posfind = -1
              else
                model.target_start = lastmatch
                model.target_end = endpos
                posfind = model.search_in_target(searchText())
              end
              occurences = occurences.succ
            end #while

            if (FXSELID(sel) == ID_REPLACE_INSEL)
              model.set_sel(startpos,endpos)
            else
              model.set_sel(lastmatch,lastmatch)
            end
            model.end_undo_action()
            status("Replaced #{occurences} occurence"+(occurences>1 ? 's':''))

          end # if
          return 1
        end

        def onCmdPrev(sender, sel, ptr)
          self.searchMode |= SEARCH_BACKWARD
          onCmdNext(sender, sel, ptr)
        end

        def onCmdNext(sender, sel, ptr)
          @havefound = false
          if searchText().empty? 
            self.searchMode &= ~SEARCH_BACKWARD
            return 1 
          end

          selstart = model.selection_start
          selend = model.selection_end
          if (searchBackward?) 
            startpos = selstart - 1;
            endpos = 0;
          else
            startpos = selend
            endpos = model.length
          end

          searchflags = (searchWholeWord?   ? Scintilla::SCFIND_WHOLEWORD : 0) |
                        (searchMatchCase?   ? Scintilla::SCFIND_MATCHCASE : 0) |
                        (searchRegExp?      ? Scintilla::SCFIND_REGEXP    : 0) |
                        (searchMatchWordStart? ? Scintilla::SCFIND_WORDSTART : 0)

          model.target_start = startpos
          model.target_end = endpos
          model.search_flags = searchflags
          posfind = model.search_in_target(searchText())

          if (posfind == -1 && searchWrap?)
            # Failed to find in indicated direction
            # so search from the beginning (forward) or from the end (reverse)
            if ( searchBackward? )
              startpos = model.length
              endpos = 0
            else
              startpos = 0
              endpos =  model.length
            end
            model.target_start = startpos
            model.target_end = endpos
            posfind = model.search_in_target(searchText())          
            status("Failing search: #{searchText()}. About to wrap")
          end
          if (posfind == -1)
            status("Failing search: #{searchText()}")
          else
            @havefound = true
            start = model.target_start()
            finish = model.target_end()
            model.set_sel(start,finish)
            status("Found '#{searchText()}' at line #{model.line_from_position(start)}, column #{model.get_column(start)}")
          end
          self.searchMode &= ~SEARCH_BACKWARD
          @app.stopModal(self)
          return 1
        end

        def restoreSettings()

          @search_history = @plugin.properties['findreplace/search_hist'] || Array.new
          @replace_history = @plugin.properties['findreplace/replace_hist'] || Array.new
          @search_history.slice!(-HISTORY_SIZE..-1) if @search_history.size > HISTORY_SIZE
          @replace_history.slice!(-HISTORY_SIZE..-1) if @replace_history.size > HISTORY_SIZE

          @last_search = @plugin.properties['findreplace/last_search']
          @last_replace = @plugin.properties['findreplace/last_replace']
          @searchmode = @plugin.properties['findreplace/search_mode'] || SEARCH_WRAP
          @search_history.each  { |elt|  @searchbox.prependItem(elt) }
          @replace_history.each { |elt|  @replacebox.prependItem(elt) }

          @wholeWordChkBtn.checkState = get_check_state(searchWholeWord?)
          @wrapChkBtn.checkState = get_check_state(searchWrap?)
          @matchCaseChkBtn.checkState = get_check_state(searchMatchCase?)
          @regExpChkBtn.checkState = get_check_state(searchRegExp?)
          @matchWordStartChkBtn.checkState = get_check_state(searchMatchWordStart?)

          unless @search_history.empty?
            self.searchText = @last_search
          end
          unless @replace_history.empty?
            self.replaceText = @last_replace
          end

        end
        
        def get_check_state(bool)
          bool ? TRUE : FALSE
        end
        
        def saveSettings()
          @plugin.properties.auto_save = false
          
          @plugin.properties["findsearch/location/x"] = self.x
          @plugin.properties["findsearch/location/y"] = self.y
          @plugin.properties['findreplace/search_hist'] = @search_history
          @plugin.properties['findreplace/last_search'] = @last_search
          @plugin.properties['findreplace/replace_hist'] = @replace_history
          @plugin.properties['findreplace/last_replace'] = @last_replace
          @plugin.properties['findreplace/search_mode'] = @searchmode
          
          @plugin.properties.auto_save = true
          @plugin.properties.save
        end

        def appendHistory(search_text, replace_text)
          @last_search = elt = searchText()
          unless @search_history.include?(elt)
            @search_history << elt 
            @search_history.shift if @search_history.size > HISTORY_SIZE
          end

          @last_replace = elt = replaceText()
          unless @replace_history.include?(elt)
            @replace_history << elt
            @replace_history.shift if @replace_history.size > HISTORY_SIZE
          end
        end

        def onCmdSearchText(sender, sel, ptr)
          return 0 if sender.text.empty?
      
          # let's keep our own history
                appendHistory(searchText(), replaceText())
      
          # only insert the new element in the combobox 
          # list if it doesn't yet exist
          found = false
          text = sender.text
          num = sender.getNumItems
          for idx in 0..num-1
            if sender.getItemText(idx) == text
              found = true
              sender.setCurrentItem(idx)
              break
            end
          end
      
          # insert the new item if needed and only keep 
          # the last HISTORY_SIZE elements
          unless found
            sender.prependItem(text)
            sender.setCurrentItem(0)
            sender.removeItem(num) if num == HISTORY_SIZE
          end
          # This mehtod is called whenever the return key is typed
          # so also search for the next/prev occurence
          (self.searchMode & SEARCH_BACKWARD) != 0 ? onCmdPrev(sender,sel,ptr) : onCmdNext(sender,sel,ptr)
          return 1
        end
        
        def onCmdMatchCase(sender, sel, ptr)
          self.searchMode ^= SEARCH_MATCHCASE
          return 1
        end
        
        def onCmdWholeWord(sender, sel, ptr)
          self.searchMode ^= SEARCH_WHOLEWORD
          return 1
        end
        
        def onCmdWrap(sender, sel, ptr)
          self.searchMode ^= SEARCH_WRAP
          return 1
        end
        
        def onCmdRegexp(sender, sel, ptr)
          self.searchMode ^= SEARCH_REGEXP
          return 1
        end

        def onCmdWordStart(sender, sel, ptr)
          self.searchMode ^= SEARCH_WORDSTART
          return 1
        end

        def onCmdCancel(sender, sel, ptr)
          saveSettings
          @app.stopModal(self)
          self.destroy
          return 1
        end

      end # class FindDialog

      ## 
      # The Search Dialog box is basically the same as the replace
      # dialog box minus some hidden fields
      #
      class FindDialog < ReplaceDialog
        
        def initialize(plugin)
          super(plugin)

          # hide all controls that are for text replacement
          accept.hide
          every.hide
          replacelabel.hide
          replacebox.hide
          inselection.hide

          accept.disable
          every.disable
          inselection.disable
          
          # if there is a piece of text selected in the current edit pane
          # then this is the text to search
          ep_slot = @plugin['/system/ui/current/EditPane']
                model = ep_slot['actions/get_ext_object'].invoke()
          text_selection = model.get_sel_text()
          unless text_selection.empty?
            self.searchText = text_selection
          end

        end

        def getDialogTitle
          "Find Text..."
        end
        
      end # class FindDialog

    end # class EditPane

  end
end

