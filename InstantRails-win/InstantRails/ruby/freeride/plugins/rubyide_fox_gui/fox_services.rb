# Purpose: Setup and initialize the core gui interfaces
#
# $Id: fox_services.rb,v 1.7 2005/11/24 18:01:35 ljulliar Exp $
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
    # This module implements/renders FreeRIDE services using FOX.
    #
    class Services
      include Fox
      extend FreeBASE::StandardPlugin
      @@dir = nil

      def Services.start(plugin)
      
        cmd_mgr = plugin["/system/ui/commands"].manager
        @@dir = Dir.getwd
        # The mainWindow won't change so we can just set it here and use it in the blocks below
        mainWindow = plugin["/system/ui/fox/FXMainWindow"].data 
        
        #Register Service Commands
        cmd_mgr.add("App/Services/FileOpen", "Open File") do |cmd_slot, patterns|
          openDialog = FXFileDialog.new(mainWindow, "Open File")
          openDialog.selectMode = SELECTFILE_EXISTING
          openDialog.patternList = patterns

          # check whether the open dialog box should show last visited directory
          # or directory of currently edited file
          if (plugin['/system/ui/current/EditPane'].is_link_slot? &&
              plugin['/plugins/rubyide_fox_gui-editpane'].manager.properties['open_dir_policy'] == 0)
            current_file = plugin['/system/ui/current/EditPane'].data
            openDialog.directory = File.dirname(current_file)
          else
            openDialog.directory = @@dir
          end

          filename = nil
          if openDialog.execute != 0
            filename = openDialog.filename
            @@dir = File.dirname(filename)
          end
          # On Windows platforms FOX returns file path with "\" so make sure
          # we normalize file names to Ruby internal representation
          if filename && (RUBY_PLATFORM =~ /(mswin32|mingw32)/)
            filename = filename.split("\\").join(File::SEPARATOR)
          end
          filename
        end
      
        cmd_mgr.add("App/Services/FileClose", "Close File") do |cmd_slot, filename|
          answer = FXMessageBox.question(
            mainWindow, 
            MBOX_YES_NO_CANCEL,
            "Unsaved Document", 
            "Do you want to save the changes\nyou made to #{File.basename(filename)}?".wrap(60)
          )
          
          result = case answer
          when MBOX_CLICKED_YES
            'yes'
          when MBOX_CLICKED_NO
            'no'
          when MBOX_CLICKED_CANCEL
            'cancel'
          else
            raise "Invalid answer from the FileCloseDialog: #{answer}"
          end
          result
        end
        
        cmd_mgr.add("App/Services/FileSaveAs", "Save File As") do |cmd_slot, file, is_new_file|
          saveDialog = FXFileDialog.new(mainWindow, 'Save File As')
          saveDialog.selectMode = SELECTFILE_ANY
          saveDialog.patternList = ['All Files (*.*)', 'Ruby Files (*.rb)']

	  # Points Save As... to home directory if it's a new file
	  if is_new_file
	    dir = (RUBY_PLATFORM =~ /(mswin32|mingw32)/ ? ENV['USERPROFILE'] : ENV['HOME'])
	  else
	    dir = File.dirname(file)
	    dir = @@dir if dir=='.'
	  end
          file = File.basename(file)
          saveDialog.directory = dir
          saveDialog.filename = File.join(dir, file)
          filename = nil
          answer = saveDialog.execute
          
          if answer==0
            result = 'cancel'
          else
            result = ['save', saveDialog.filename]
          end
          result
        end
        
        cmd_mgr.add("App/Services/YesNoCancelDialog", "Yes/No/Cancel Dialog Box") do |cmd_slot, title, msg|
          case FXMessageBox.information(mainWindow, MBOX_YES_NO_CANCEL, title, msg.wrap(60))
          when MBOX_CLICKED_YES
            "yes"
          when MBOX_CLICKED_NO
            "no"
          when MBOX_CLICKED_CANCEL
            "cancel"
          end
        end
        
        cmd_mgr.add("App/Services/YesNoDialog", "Yes/No Dialog Box") do |cmd_slot, title, msg|
          case FXMessageBox.information(mainWindow, MBOX_YES_NO, title, msg.wrap(60))
          when MBOX_CLICKED_YES
            "yes"
          when MBOX_CLICKED_NO
            "no"
          end
        end
        
        cmd_mgr.add("App/Services/MessageBox", "Display MessageBox") do |cmd_slot, title, msg|
          FXMessageBox.information(mainWindow, MBOX_OK, title, msg.wrap(60))
        end
        
        cmd_mgr.add("App/Services/Shutdown", "Shutdown Freeride") do |cmd_slot|
          done = cmd_mgr.command('App/Project/CloseAll').invoke
          if done #false means the CloseProject was aborted
            mainWindow.shutdown
          end        
        end
        
        cmd_mgr.add("App/Services/DirDialog", "Browse for a directory") do |cmd_slot, title, dir, parent|
          if parent
            dlg = FXDirDialog.new(parent, title)
          else
            dlg = FXDirDialog.new(mainWindow, title)
          end
          dlg.setDirectory(dir) if dir and dir.length > 0
          
          r = nil
          if dlg.execute == 1
            r = dlg.getDirectory
          end
          r
        end
        plugin.transition(FreeBASE::RUNNING)
      end
      
    end  # module FoxServices
    
  end
end


##
# Add a new wrap method to string which wrap long message
# to max_size character per line
#
class String
  def wrap(max_size)
    all = []
    line = nil
    str = self.dup
    while (line = str.slice!(/.{#{max_size}}/))
      all.push(line)
    end
    all.push(str).join("\n")
  end
end
