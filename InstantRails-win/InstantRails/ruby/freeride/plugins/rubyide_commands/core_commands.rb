# Purpose: Setup and initialize the core gui interfaces
#
# $Id: core_commands.rb,v 1.21 2006/05/25 07:41:08 ljulliar Exp $
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
  
  module Commands
    
    ##
    # This plugin/class defines the core commands pertaining to the the
    # FreeRIDE application itself.
    #
    class CoreCommands
      
      extend FreeBASE::StandardPlugin
      
      def self.start(plugin)
        cmd_mgr = plugin["/system/ui/commands"].manager
        key_mgr = plugin["/system/ui/keys"].manager
        
        ###### PROJECT COMMANDS #####
        cmd_mgr.add("App/Project/CloseAll", "Close &All Projects") do |cmd_slot|
          cmd_slot['/project'].manager.close_all_projects
        end
        
        cmd_mgr.add("App/Project/Close", "&Close Project") do |cmd_slot|
          cmd_slot['/project'].manager.open_default_project
        end
        
        cmd_mgr.add("App/Project/Open", "&Open Project") do |cmd_slot|
          filename = cmd_mgr.command('App/Services/FileOpen').invoke(["FreeRIDE Project Files (*.frproj)"])
          cmd_slot['/project'].manager.open_project(filename) if filename
        end
        
        cmd_mgr.add("App/Project/New", "&New Project") do |cmd_slot|
          cmd_slot['/project'].manager.new_project
        end
        
        cmd_mgr.add("App/Project/Load", "&Load Project") do |cmd_slot, frproj_file|
          cmd_slot['/project'].manager.open_project(frproj_file)
        end
        
        
        
        ###### FILE COMMANDS ######
        cmd_mgr.add("App/File/New", "&New") do |cmd_slot|
          editpane_slot = cmd_slot['/system/ui/components/EditPane'].manager.add
          editpane_slot.manager.mark_new
          editpane_slot.manager.make_current
          cmd_slot['/project/active/default'].manager.attach_editpane(editpane_slot)
          editpane_slot
        end
        key_mgr.bind("App/File/New", :ctrl, :N)
        
        cmd_mgr.add("App/File/Open", "&Open") do |cmd_slot|
          filename = cmd_mgr.command('App/Services/FileOpen').invoke(["All Files (*)", "Ruby Files (*.rb,*.rbw)"])
          if filename
            editpane_slot = nil
            cmd_slot['/system/ui/components/EditPane'].each_slot do |editpane|
              if editpane.data == filename
                editpane_slot = editpane
                editpane_slot.manager.make_current
                break
              end
            end
            unless editpane_slot
               editpane_slot = cmd_slot['/project/active/default'].manager.open_file(filename)
            end
            editpane_slot
          end
        end
        key_mgr.bind("App/File/Open", :ctrl, :O)
        
        cmd_mgr.add("App/File/Load", "Load") do |cmd_slot, filename|
          if filename && File.exist?(filename)
            editpane_slot = nil
            cmd_slot['/system/ui/components/EditPane'].each_slot do |editpane|
              if editpane.data == filename
                editpane_slot = editpane
                editpane_slot.manager.make_current
                break
              end
            end
            unless editpane_slot
              editpane_slot = cmd_slot['/system/ui/components/EditPane'].manager.add
              editpane_slot.manager.load_file(filename)
              editpane_slot.manager.make_current
              cmd_slot['/project/active/default'].manager.attach_editpane(editpane_slot)
            end
            editpane_slot
          end
        end
        
        cmd = cmd_mgr.add("App/File/Close", "&Close", "Close File...") do |cmd_slot|
          editpane_slot = cmd_slot['/system/ui/current/EditPane']
          if editpane_slot.manager
            prj_mngr = cmd_slot['/project'].manager
            project = prj_mngr.get_project_for_editpane(editpane_slot)
            if project 
              project.manager.close_ep(editpane_slot)
            else
              editpane_slot.manager.close if editpane_slot.manager
            end
          end
        end
        cmd.availability = plugin['/system/ui/current'].has_child?('EditPane')
        key_mgr.bind("App/File/Close", :ctrl, :W)
        
        cmd = cmd_mgr.add("App/File/CloseAll", "C&lose All", "Close All Files...") do |cmd_slot|
          done = true
          cmd_slot['/system/ui/components/EditPane'].each_slot do |editpane|
            if editpane.manager.close(true)=="cancel"
              done = false 
              break
            end
          end
          plugin['log/debug'] << "returning #{done}"
          done
        end
        cmd.availability = plugin['/system/ui/current'].has_child?('EditPane')
        key_mgr.bind("App/File/CloseAll", :ctrl, :shift, :W)
        
        [ "Close", "CloseAll" ].each do |command|
          cmd_mgr.command("App/File/"+command).manage_availability do |command|
            plugin['/system/ui/current'].subscribe do |event, slot|
              if slot.name=="EditPane"
                case event
                when :notify_slot_link
                  command.availability = true
                when :notify_slot_unlink
                  command.availability = false
                end
              end
            end
          end
        end
        
        cmd_mgr.add("App/File/SaveAll", "S&ave All", "Save All Files...") do |cmd_slot|
          done = true
          cmd_slot['/system/ui/components/EditPane'].each_slot do |editpane|
            if editpane.manager && editpane.manager.modified?
              if editpane.manager.save=="no"
                done = false 
                break
              end
            end
          end
          done
        end
        
        cmd = cmd_mgr.add("App/File/Save", "&Save") do |cmd_slot|
          editpane = cmd_slot['/system/ui/current/EditPane'].manager
          editpane.save if editpane
        end
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
        key_mgr.bind("App/File/Save", :ctrl, :S)
        
        cmd = cmd_mgr.add("App/File/SaveAs", "Save &As...", "Save File As...") do |cmd_slot|
          editpane = cmd_slot['/system/ui/current/EditPane'].manager
          editpane.save_as if editpane
        end
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
        key_mgr.bind("App/File/SaveAs", :ctrl, :shift, :S)
        
        ###### EDIT COMMANDS ######
        
        cmd_mgr.add("App/Edit/Undo", "Undo") do |cmd_slot|
          editpane = cmd_slot["/system/ui/current/EditPane"].manager
          editpane.undo if editpane
        end
        key_mgr.bind("App/Edit/Undo", :ctrl, :Z)
        
        cmd_mgr.add("App/Edit/Redo", "Redo") do |cmd_slot|
          editpane = cmd_slot["/system/ui/current/EditPane"].manager
          editpane.redo if editpane
        end
        key_mgr.bind("App/Edit/Redo", :ctrl, :Y)
        
        cmd_mgr.add("App/Edit/Cut", "Cut", "Cut selected text to clipboard") do |cmd_slot|
          editpane = cmd_slot["/system/ui/current/EditPane"].manager
          editpane.cut if editpane
        end
        key_mgr.bind("App/Edit/Cut", :ctrl, :X)
        
        cmd_mgr.add("App/Edit/Copy", "Copy", "Copy selected text to clipboard") do |cmd_slot|
          editpane = cmd_slot["/system/ui/current/EditPane"].manager
          editpane.copy if editpane
        end
        key_mgr.bind("App/Edit/Copy", :ctrl, :C)
        
        cmd_mgr.add("App/Edit/Paste", "Paste", "Paste text from clipboard") do |cmd_slot|
          editpane = cmd_slot["/system/ui/current/EditPane"].manager
          editpane.paste if editpane
        end
        key_mgr.bind("App/Edit/Paste", :ctrl, :V)
        
        
        ###### VIEW COMMANDS ######

        cmd = cmd_mgr.add("App/View/LineNumbers", "Line Numbers", "View Line Numbers") do |cmd_slot|
	  value = plugin['/plugins/rubyide_fox_gui-editpane/properties/line_numbers'].data
	  value = !value
	  plugin['/plugins/rubyide_fox_gui-editpane/properties/line_numbers'].data = value
	  plugin['/system/ui/components/EditPane'].each_slot do |slot|
	    slot.manager.linenumbers_visible = value
	  end
	  cmd_slot.manager.checked = value
        end
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

        cmd = cmd_mgr.add("App/View/EndOfLine", "End Of Line", "View End of Line Characters") do |cmd_slot|
	  value = plugin['/plugins/rubyide_fox_gui-editpane/properties/eol'].data
	  value = !value
	  plugin['/plugins/rubyide_fox_gui-editpane/properties/eol'].data = value
	  plugin['/system/ui/components/EditPane'].each_slot do |slot|
	    slot.manager.eol_visible = value
	  end
	  cmd_slot.manager.checked = value
        end
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

        cmd = cmd_mgr.add("App/View/Whitespace", "Whitespace", "View Whitespace") do |cmd_slot|
	  value = plugin['/plugins/rubyide_fox_gui-editpane/properties/white_space'].data
	  value = !value
	  plugin['/plugins/rubyide_fox_gui-editpane/properties/white_space'].data = value
	  plugin['/system/ui/components/EditPane'].each_slot do |slot|
	    slot.manager.whitespace_visible = value
	  end
	  cmd_slot.manager.checked = value
        end
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
        
        
        ###### MISC COMMANDS ######
        
        cmd_mgr.add("App/Exit", "E&xit") do |cmd_slot|
          cmd_mgr.command('App/Services/Shutdown').invoke
        end
        key_mgr.bind("App/Exit", :ctrl, :Q)

        cmd_mgr.add("App/About", "&About FreeRIDE...") do |cmd_slot|
          v_slot = cmd_slot['/system/properties/version']
          cmd_mgr.command('App/Services/MessageBox').invoke("About FreeRIDE", 
            "This is FreeRide version #{FreeRIDE::VERSION_MAJOR}.#{FreeRIDE::VERSION_MINOR}.#{FreeRIDE::VERSION_RELEASE}")
        end
        
        begin
          if RUBY_PLATFORM =~ /(mswin32|mingw32)/
            require "win32ole"
            cmd_mgr.add("App/Help", "&Help") do |cmd_slot|
              shell = WIN32OLE.new('WScript.shell')
              shell.Run "doc\\userhelp.html", 1, false       
            end
          elsif RUBY_PLATFORM =~ /powerpc/
            # For OSX use open
            cmd_mgr.add("App/Help", "&Help") do |cmd_slot|
              system("open #{Dir.pwd}/doc/userhelp.html")
            end
          else
            # For non-win32 platform assume netscape
            cmd_mgr.add("App/Help", "&Help") do |cmd_slot|
              system("netscape -remote \"openurl(file://#{Dir.pwd}/doc/userhelp.html,new-window)\"")
            end
          end
        rescue Exception
          cmd_mgr.add("App/Help", "&Help") do |cmd_slot|
          cmd_mgr.command('App/Services/MessageBox').invoke("Help Unavailable", 
            "Help is not currently available in FreeRIDE.")
          end
        end
        
        plugin.transition(FreeBASE::RUNNING)
      end
      
    end
    
  end
  
end
