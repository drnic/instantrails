# Purpose: Class managing debugger breakpoints
#
# $Id: breakpoint.rb,v 1.1 2003/03/23 22:38:59 ljulliar Exp $
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
# Copyright (c) 2003 Laurent Julliard. All rights reserved.
#

module FreeRIDE; module GUI

##
# This module defines the FreeRIDE Debugger breakpoints
#
class BreakpointManager
 
  def initialize(debugger)
    @subscribers = Hash.new  # editpane brkpt queue we've subscribed to
    @breakpoints = Array.new # all active breakpoints
    @debugger = debugger
    @plugin = debugger.plugin
    @cmd_mgr = @plugin['/system/ui/commands'].manager
  end
  
  ## 
  # Add a breakpoint in the remote debugger only if it hasn't been set
  # already
  #
  # temp = true means that when the breakpoint is reached we 
  # delete it (used by run to cursor function)
  #
  def add(file,line, temp = false)
    return unless index(file,line).nil?
    idx = @debugger.debuggee.add_break_point(file, line, temp)
    @breakpoints[idx] = Breakpoint.new(file,line) if temp == false
    @plugin.log_info << "Set breakpoint #{idx} at #{File.basename(file)}:#{line}"
    return idx
  end
  
  ##
  # Delete a breakpoint
  #
  def delete(file,line)
    if (idx = index(file,line))
      @breakpoints[idx] = nil
      done = @debugger.debuggee.delete_break_point(idx)
    end
    if done
      @plugin.log_info << "Breakpoint #{idx} deleted."
    else
      @plugin.log_info << "Breakpoint #{idx} is not defined."
    end
  end
  
  ##
  # Given a (file,line) couple find the corresponding break point index in the
  # @breakpoint Array.
  #
  def index(file,line)
    idx=nil
    @breakpoints.each_index do |idx|
      next unless @breakpoints[idx]
      return idx if @breakpoints[idx].file == file && @breakpoints[idx].line == line
    end
    nil
  end
  
  ##
  # Return the breakpoint object at index idx
  #
  def [] (idx)
    @breakpoints[idx]
  end 
  
  ##
  # Set up all the break points placed on a given file in the debugger
  # if it has never been loaded before. (Note: Editpanes keep track of
  # where breakpoints were placed from one FR session to another.
  #
  def set_all(file)
    lines = @cmd_mgr.command('EditPane/GetBreakpointsForFile').invoke(file)
    unless lines.nil?
      lines.each { |line| self.add(file,line) }
    end
  end
  
  ##
  # Subscribe to the given editpane breakpoint queue
  #
  def subscribe(slot)
    # Make sure any pending add/delete brkpoints events that occured
    # before this session is cleared
    slot['breakpoints'].queue.clear
    
    # Now subscribe
    sub_id = slot['breakpoints'].subscribe do |event, slot|
      if event == :notify_queue_join 
        while action = slot.queue.leave
          cmd, line = action
          file = slot.parent.data
          if cmd == 'add'
            self.add(file, line)
          else
            self.delete(file, line)
          end
        end
      end
    end
    @subscribers[slot['breakpoints']] = sub_id
    puts "dbg subscribe to #{slot.path} breakpoints" if DEBUG
  end
  
  ##
  # Unsubscribe from all the  breakpoints event queue at once
  #
  def unsubscribe_all
    @subscribers.each_pair do |slot,id|
      slot.unsubscribe(id)
    end
    @subscribers = {}
  end
    
end

class Breakpoint
  attr_reader :file, :line
  def initialize(file,line)
    @file=file
    @line=line
  end
end

class WatchpointManager < BreakpointManager

  ## 
  # Add a watchpoint in the remote debugger only if it
  # hasn't been set before with the same expression
  #
   def add(expr, gui_idx)
     return unless index(expr,gui_idx).nil?
     idx = @debugger.debuggee.add_watch_point(expr)
     @breakpoints[idx] = Watchpoint.new(expr,gui_idx) if idx
     @plugin.log_info << "Set watchpoint #{idx}: #{expr}"
     return idx
   end

  ##
  # Delete a watchpoint
  #
   def delete(expr,gui_idx)
     if (idx = index(expr,gui_idx))
       @breakpoints[idx] = nil
       done = @debugger.debuggee.delete_watch_point(idx)
     end
     if done
       @plugin.log_info << "Watchpoint #{idx} deleted."
     else
       @plugin.log_info << "Watchpoint #{idx} is not defined."
     end
     return done
   end
  
  ##
  #
end

class Watchpoint < Breakpoint
  alias_method :expr, :file
end

end; end
