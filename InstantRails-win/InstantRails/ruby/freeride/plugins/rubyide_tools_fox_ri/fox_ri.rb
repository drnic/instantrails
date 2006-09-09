# Purpose: Run ri fox gui in a dockpane
#
# $Id: fox_ri.rb,v 1.5 2005/03/30 14:05:03 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent at moldus dot org>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Laurent Julliard All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

$: << File.join($FR_CODEBASE,'plugins','rubyide_tools_fox_ri','fxri')
require 'rubyide_tools_fox_ri/fxri/fxri'

module FreeRIDE; module GUI
  class RI < Component
    extend FreeBASE::StandardPlugin
    include Fox

    def self.start(plugin)

      # There can only be one RI session at a time
      base_slot = plugin["/system/ui/components/RI"]
      ComponentManager.new(plugin, base_slot, RI, 1)

      @@ri = nil

      #---------------------------------------
      # After loading fxri we have to do some dirty tricks on fxri
      # global variables
      $cfg.app.font.name.unshift(FXApp::instance.normalFont.name) # use FR default font
      $cfg.ri_font = ["Lucidatypewriter","Bitstream Vera Sans Mono", "Courier New", "Courier"]
      $cfg.launch_irb = false # do not launch irb
      $cfg.icons_path = File.join(plugin.plugin_configuration.full_base_path,"icons")# use FR plugin icons
      $cfg.icons.klass = "class.png"
      $cfg.icons.class_method = "module.png"
      $cfg.icons.instance_method = "method.png"
      $cfg.text.help = %|This is the Ruby Documentation plugin, a graphical interface to the <em>Ruby</em> documentation based on FXri. At any time in the FreeRIDE editor, you can type <b>F1</b> to get instant help on the keyword below or next to the cursor.
FXri also comes with a search engine with quite a few features. Here are several examples:
'<em>Array</em>': Lists all classes with the name <em>Array</em>. Note that upcase words are treated case sensitive, lowercase words insensitive.
'<em>array sort</em>': Everything that contains both <em>array</em> and <em>sort</em> (case insensitive).
'<em>array -Fox</em>': Everything that contain the name <em>array</em> (case insensitive), but not <em>Fox</em> (case sensitive).
After searching just press <em>down</em> to browse the search results. Press <em>Tab</em> to move back into the search field.
If you have any problems, questions or suggestions about FXri please contact the author at <b>martin.ankerl@gmail.com</b>.|
      #---------------------------------------

      # Handle icons
      plugin['/system/ui/icons/RI'].subscribe do |event, slot|
        if event == :notify_slot_add
          app = plugin['/system/ui/fox/FXApp'].data
          path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
          if FileTest.exist?(path)
            slot.data = Fox::FXPNGIcon.new(app, File.open(path, "rb").read)
            slot.data.create
          end
        end
      end

      # Create the Run RI command and show it in the 
      # "view" area of the toolbar rather than the "run" area
      cmd_mgr = plugin["/system/ui/commands"].manager
      cmd_ri = cmd_mgr.add("App/Run/RunRI","&Ruby Doc") do |cmd_slot|
	@@ri = RI.new(plugin, base_slot) unless @@ri
	@@ri.lookup
        @@ri.show
      end
      plugin["/system/ui/keys"].manager.bind("App/Run/RunRI", :F1)
      cmd_ri.icon = "/system/ui/icons/RI/ri"
      plugin["/system/ui/current/ToolBar"].manager.add_command("View", "App/Run/RunRI")

      
      # Insert the run RI command in the Run menu
      runmenu = plugin["/system/ui/components/MenuPane/Run_menu"].manager
      runmenu.add_command("App/Run/RunRI")    

      # Create the "view RI" in the View menu to hide/show the RI pane
      cmd_view_ri = cmd_mgr.add("App/View/RI","&Ruby Doc","View Ruby Documentation") do |cmd_slot|
	@@ri.toggle if @@ri
      end

      # manage availability of the RI View menu
      cmd_view_ri.availability = plugin['/system/ui/current'].has_child?('RI')
      cmd_view_ri.manage_availability do |command|
	plugin['/system/ui/current'].subscribe do |event, slot|
	  if slot.name=="RI"
	    case event
	    when :notify_slot_link
	      command.availability = true
	    when :notify_slot_unlink
	      command.availability = false
	    end
	  end
	end
      end

      # and attach it to the View menu pane
      viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
      viewmenu.add_command("App/View/RI")
      viewmenu.uncheck("App/View/RI")

      # Start the RI plugin if it was there at the last session
      plugin["/system/state/all_plugins_loaded"].subscribe do |event, slot|
        if slot.data == true
          if plugin.properties["Open"]
	    # first time re-opening. Don't do a lookup so that
	    # we see the help message
	    @@ri = RI.new(plugin, base_slot) unless @@ri
	    @@ri.show
          end
        end
      end
      
      plugin.transition(FreeBASE::RUNNING)
    end


    def initialize(plugin, slot)
      @plugin = plugin
      @slot = slot

      @viewmenu = plugin["/system/ui/components/MenuPane/View_menu"].manager
      @plugin['/system/ui/current'].link('RI',@slot)

      # Create the RI text frame and reparent it to the dockpane
      main_window = plugin["/system/ui/fox/FXMainWindow"].data
      @frm = FXri.new(main_window, FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y,0,0,0,0,0,0,0,0,0,0)
      @frm.hide
      @frm.create

      # Dock the RI frame now that everything is ready
      @dockpane_slot = plugin['/system/ui/components/DockPane'].manager.add("Ruby Doc")
      @dockpane_slot.data = @frm
      @dockpane_slot.manager.dock('south')
     
      # When the dockpane informs us that it is opened or closed
      # adjust the menu item and properties accordingly 
      @dockpane_slot["status"].subscribe do |event, slot|
        if event == :notify_data_set
          if @dockpane_slot["status"].data == 'opened'
            @checked = true
            @viewmenu.check("App/View/RI")
            @plugin.properties["Open"] = true
          elsif @dockpane_slot["status"].data == 'closed'
            @viewmenu.uncheck("App/View/RI")
            @checked = false
            @plugin.properties["Open"] = false
          end
        end
      end

      setup_actions

      plugin.log_info << "RI renderer created"
    end

    def setup_actions
      bind_action("lookup", :lookup)
    end
        
    def bind_action(name, meth)
      @slot["actions/#{name}"].set_proc method(meth)
    end

    def lookup(string=nil)
      show # show dockpane and/or bring to front
      unless string
	return unless @plugin['/system/ui/current/EditPane'].is_link_slot?
	ep_slot = @plugin['/system/ui/current/EditPane']
	word,text_before,text_after = ep_slot['actions/help_lookup'].invoke
	# if there is class/module name before the selected word then look for
	# both the identifier and the class/module to make for a more accurate
	#search
	if text_before =~ /([A-Z][A-Za-z0-9_]*)\.$/
	  word = "#{$1} #{word}"
	end
	string = word
      end
      @frm.go_search(string)
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

  end

end; end
