# Purpose: Plugin to comment and uncomment blocks of code
#
# $Id: block_commenter.rb,v 1.2 2005/11/03 04:36:16 martinleech Exp $
#
# Authors:  Martin Leech <leech.martin AT gmail.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Martin Leech All rights reserved.
#

module FreeRIDE
  module Tools
    
    class BlockCommenter
      extend FreeBASE::StandardPlugin
  
      # initialize this plugin
      def BlockCommenter.start(plugin)
        # Create an instance of the our command object
        the_cmd_object = CommenterCommand.new(plugin)
  
        cmd_manager = plugin['/system/ui/commands'].manager
        cmd_manager.add('Edit/CommentBlock','Comment Block') do |cmd_slot|
          the_cmd_object.comment_block()
        end
        cmd_manager.add('Edit/UncommentBlock','Uncomment Block') do |cmd_slot|
          the_cmd_object.uncomment_block()
        end
        
        # Insert the commands into the Edit menu
        edit_menu = plugin['/system/ui/components/MenuPane/Edit_menu'].manager
        edit_menu.add_command('Edit/CommentBlock')
        edit_menu.add_command('Edit/UncommentBlock')
        
        plugin["/system/ui/keys"].manager.bind("Edit/CommentBlock", :ctrl, :K)
        plugin["/system/ui/keys"].manager.bind("Edit/UncommentBlock", :shift, :ctrl, :K)
        plugin.transition(FreeBASE::RUNNING)
      end
  
  
      class CommenterCommand
  
        COMMENT_CHAR = "#"
        COMMENTED_LINE_REGEXP = /^(\s*)#{COMMENT_CHAR}(.*)$/
        
        def initialize(plugin)
          @plugin = plugin
        end
  
        def comment_block()
          change_block {|line|comment_line(line)}
        end
  
        def uncomment_block()
          change_block {|line|uncomment_line(line)}
        end
        
        def change_block()
          ext_object = get_ext_object
          
          start_line =  ext_object.line_from_position(ext_object.selection_start)
          end_line =  ext_object.line_from_position(ext_object.selection_end)
          is_caret_at_start = (ext_object.get_current_pos < ext_object.get_anchor)
          select_full_block(start_line, end_line, is_caret_at_start, ext_object)
        
          text = ext_object.get_sel_text
          new_text = ""
          text.each_line do |ln|
            new_text += yield(ln)
          end
          
          ext_object.begin_undo_action()
          ext_object.replace_sel(new_text)
          ext_object.end_undo_action()
          
          #reselect block
          select_full_block(start_line, end_line, is_caret_at_start, ext_object)
          ext_object = nil
        end
        
        def comment_line(line)
          COMMENT_CHAR + line
        end
        
        def uncomment_line(line)
          line.sub(COMMENTED_LINE_REGEXP, '\1\2')
        end
        
        def get_ext_object
          @plugin['/system/ui/current/EditPane/actions/get_ext_object'].invoke()
        end
        
        # Expand selection so that complete lines are selected
        def select_full_block(start_line, end_line, is_caret_at_start, ext_object)
          new_sel_start = ext_object.position_from_line(start_line)
          new_sel_end = ext_object.get_line_end_position(end_line)
          
          if is_caret_at_start
            new_sel_start, new_sel_end = new_sel_end, new_sel_start
          end
          
          ext_object.set_sel(new_sel_start, new_sel_end)
        end
        
      end
    end
  
  end
end 