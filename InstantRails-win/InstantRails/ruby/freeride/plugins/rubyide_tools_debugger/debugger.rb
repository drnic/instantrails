# Purpose: Setup and initialize the FR Debugger
#
# $Id: debugger.rb,v 1.33 2006/05/25 07:42:33 ljulliar Exp $
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

require 'drb'
require 'singleton'
require 'rubyide_tools_debugger/breakpoint'
require 'tempfile'
# if RUBY_PLATFORM =~ /(mswin32|mingw32)/
# require 'win32/process'
# require 'win32/open3'
# else
# require 'open3'
# end

module FreeRIDE; module GUI

DEBUG = false

##
# This module defines the FreeRIDE Debugger
#
class Debugger < Component
  extend FreeBASE::StandardPlugin

  def self.start(plugin)

    # Manage the Debuggers in a pool. Although there can be only one
    # debugger session active right now may be several will be allowed in the
    # future
    base_slot = plugin["/system/ui/components/Debugger"]
    ComponentManager.new(plugin, base_slot, Debugger, 1)

    # Create the Debug menu item and associate a command with it
    # When the command is invoked create a new debugger session
    # unless there is one already and start it
    cmd_mgr = plugin['/system/ui/commands'].manager
    
    cmd = cmd_mgr.add("App/Run/Debugger", "&Debugger") do |cmd_slot|
      if plugin['/system/ui/current/Debugger'].is_link_slot?
        debugger = plugin['/system/ui/current/Debugger']
        if debugger.manager.running?
          debugger.manager.show
        else
          debugger.manager.start
        end
      else
        debugger = base_slot.manager.add
        debugger.manager.start
      end
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

    # Insert the debugger menu item in the run menu and bind it
    # to the F10 key
    runmenu = plugin["/system/ui/components/MenuPane/Run_menu"].manager
    runmenu.add_command("App/Run/Debugger")
    
    key_mgr = plugin['/system/ui/keys'].manager
    key_mgr.bind("/App/Run/Debugger", :F10)

    # Now only is the plugin running
    plugin.transition(FreeBASE::RUNNING)
  end

  include DRbUndumped

  attr_reader :slot, :running, :debuggee, :plugin

  ##
  # Instantiate a new  debugger session . Only one session at a time for now
  # Do not start it yet (see start)
  #
  def initialize(plugin, base_slot)
    setup(plugin, base_slot)
    @cmd_mgr = plugin["/system/ui/commands"].manager
    @plugin['/system/ui/current'].link('Debugger',base_slot)
    @action_queue = Array.new # must be initialized before starting
    @plugin.log_info << "Debugger session created #{base_slot.path}"
 end

  ##
  # Prompt a message in the status bar
  #
  def status(msg)
    @plugin['/system/ui/current/StatusBar/actions/prompt'].invoke(msg)
  end

  ##
  # Actually start the debugger session. Run the remote debugger,
  # open a pipe for debugger command,....
  #
  def start

    # if not the current Editpane is not a real edit pane then do nothing
    return unless @plugin['/system/ui/current/EditPane'].managed?

    # Check if the file is modified. if so must save it before debugging
    ep = @plugin['/system/ui/current/EditPane']
    file = ep.manager.filename

    if @plugin.properties['save_before_running']
      @cmd_mgr.command("App/File/SaveAll").invoke
    else
      if ep.manager.modified? || ep.manager.new?
        answer = @cmd_mgr.command("App/Services/YesNoDialog").invoke("Save Changes before debug...", "You must first save the file before running the debugger. Save changes to '#{file}'?")
        return unless answer == 'yes'
        ep.manager.save
      end
    end
    # update file name in case it was changed by a 'save as...'
    file = ep.manager.filename  

    # see if we need to show the dialog box with configuration panel
    if @plugin.properties['config_before_running']
      # not implemented yet @actions['show_config'].invoke
    end

    # all ok show the debugger
    show

    # initialize variables
    @loaded_files = Hash.new
    @running = false
    @action_queue = Array.new


    # open the debugger command pipe
    #open_pipe()

    # start the remote debugger
    # FIXME: in the future we should create "debugging profiles" where a user can 
    # indicate in a dialog box what ruby interpreter to use, what include dir, what module
    # to include, command line arguments...
    debuggee_file = File.join("#{@plugin.plugin_configuration.full_base_path}","debuggee.rb")
    drb_file = File.join(@plugin['/system/properties/config/codebase'].data,'redist','drb','drb')
    drb_file = 'drb'
    ruby_path = @plugin.properties['path_to_ruby']
    ruby_path = 'ruby' if (ruby_path == '' || ruby_path.nil?)
    exec_dir = @plugin.properties['working_dir']
    exec_dir = File.dirname(file) if (exec_dir == '' || exec_dir.nil?)

    tmpfile = Tempfile.new("fr_dbg_"); tmpfile.close
    exec_options = @plugin.properties['cmd_line_options']
    exec_options = '' if (exec_options.nil?)
    exec_args = exec_options + " #{tmpfile.path}"
    
    # before running the command make sure that the ruby 
    # interpreter is here or ask the user to specify a path
    unless FileTest.exist?(ruby_path)
      @cmd_mgr.command('App/Services/MessageBox').invoke("Where is Ruby?",
        "I can't find the default Ruby interpreter. Please configure the path to ruby in the Debugger/Run preference box")
    end

    command = "#{ruby_path} -C \"#{exec_dir}\" -r \"#{drb_file}\" -r \"#{debuggee_file}\" \"#{file}\" #{exec_args}"
    if @plugin.properties['run_in_terminal']
      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
	command = "start CMD /K "+command
      else
	command = "xterm -e "+command
      end
    end
    #puts "command: #{command}"
    @plugin.log_info << "Running debugger command: #{command}"

    # On Windows build the popen3 method doesn't work because
    # the fork() is not supported
    #if RUBY_PLATFORM =~ /(mswin32|mingw32)/
      @inp = @out = IO.popen(command,"w+")
      @err = nil
    #else
      #@inp, @out, @err = Open3.popen3(command)
    #end


    begin
      require 'timeout'
      Timeout.timeout(5) { 
	while File.stat(tmpfile.path).zero?
	  sleep 0.1
	end
      }
      # fetch Drb URI and process ID from temp file
      tmpfile.open
      debugUri, pid = tmpfile.gets.chomp.split(",")
      tmpfile.close(true)

      # connect to remote process
      @debugSvr = DRb.start_service()
      @debuggee = DRbObject.new(nil, debugUri)
      debuggeeId = @debuggee.attach(self)
    rescue
      status("Debugger process aborted!!")
      @cmd_mgr.command('App/Services/MessageBox').invoke('FATAL ERROR!',  "#{$!} / Unexpected Error while launching the remote Ruby process with #{command}")
      return
    end

    @pid = pid.to_i
    if @plugin.properties['run_in_terminal']
      @term_pid = @out.pid
    end
    @plugin.log_info << "Remote Debugger Started at URI : #{debugUri}, process id #{@pid}"

    #puts "pid = #{@pid}, term_pid = #{@term_pid}"
    # if the process was run through a terminal then the child pid is
    # the one of the terminal not the one of the ruby process
    t = Thread.new(@term_pid.nil? ? @pid : @term_pid, self) { |pid, dbg|
      Process.waitpid(pid)
      stop
    }

    trap( "INT" ) do
      self.pause
      #puts "Trap INT"
      #@debuggee.signal( "INT" )
      #  @debugSvr.thread.join
    end

    @paused = true

    # create the watchpoint and breakpoint manager (only after
    # debuggee is running)
    @brk_mgr = BreakpointManager.new(self)
    @watch_mgr = WatchpointManager.new(self)

    # attach process stdout and err to text console
    @actions['attach_stderr'].invoke(@err) unless @err.nil?
    @actions['attach_stdout'].invoke(@out)
    @actions['attach_stdin'].invoke(@inp)

    # we subscribe to the Edit Pane pool so that whenever a new edit pane is
    # created we subscribe to the 'breakpoints' sub slot. This is  where edit panes
    # breakpoints addition/deletion events are posted. When these events
    # are received we can act accordingly on the remote debugger
    @plugin['/system/ui/components/EditPane'].subscribe { |event, slot|
      if (event == :notify_slot_add &&  slot.parent.name == 'EditPane')
        @brk_mgr.subscribe(slot)
      end
    }

    # make sure that we also subscribe to existing  edit panes if any
    # also clear any error marker that may have been created in a previous
    # session
    @plugin['/system/ui/components/EditPane'].each_slot { |slot|
      @brk_mgr.subscribe(slot)
      slot['actions/clear_errorline'].invoke
    }

    # start GUI
    @actions['start'].invoke

    # get the list of watches memorized in the GUI and set them up
    gui_idx=0
    @actions['list_watchpoints'].invoke().each do |expr|
      @watch_mgr.add(expr,gui_idx)
      gui_idx = gui_idx.succ
    end

    # Warning about ouput bug
    if !@plugin.properties['run_in_terminal'] && RUBY_PLATFORM =~ /(mswin32|mingw32)/
      @actions['print_stderr'].invoke("*** WARNING *** Windows users should check the \"Run process in terminal\" check box in the Debugger Preferences\nto see STDOUT and STDERR output.\n")
    end

    # All good now!
    @running = true
    @plugin.log_info << "Debugger session started #{@base_slot.path}"
    status("Debugger process started  (#{debugUri}, process id #{@pid})")

  end

  ##
  # Stop the debugger session
  #
  def stop()
    return unless @running
    pause
    @actions['detach_stderr'].invoke(@err) if @err
    @actions['detach_stdout'].invoke(@out)
    @actions['detach_stdin'].invoke(@inp)
    show_debugline(@file,nil)
    @brk_mgr.unsubscribe_all()
    reset_loaded_file()
    @running = false
    @debuggee = SilentDebuggee.instance
    @plugin.log_info << "Debugger session stopped #{@base_slot.path}"
    status("Ruby Process Stopped (PID = #{@pid})")
  end

  ##
  # Show the line in the file the debugger is currently pointing to
  # open the file if not already loaded in one of the Edit panes.
  # If line is nil it removes the line marker, If file is nil do nothing
  # If error is true then show the error marker on the line
  #
  def show_debugline(file,line,error=false)
    return if file.nil?
    ep_slot = @cmd_mgr.command("EditPane/FindFile").invoke(file)

    if ep_slot.nil?
      ep_slot = @cmd_mgr.command("App/File/Load").invoke(file)
    end

    ep_slot['actions/make_current'].invoke
    if error
      ep_slot['actions/show_errorline'].invoke(line)
    else
      ep_slot['actions/show_debugline'].invoke(line)
    end
  end

  ##
  # Clear the highlighted line the debugger is currently pointing
  # If error is true then clear the error marker
  #
  def clear_debugline(file, error=false)
    show_debugline(file,nil,error)
  end

  ##
  # Return the line number (starting at 1) the cursor is on
  # in the current edit pane
  #
  def cursor_line()
    ep_slot = @plugin['/system/ui/current/EditPane']
    line = ep_slot['actions/get_cursor_line'].invoke
    return line
  end

  ##
  # add a file to the list of files loaded by the debugger
  # subscribe to the corresponding edit pane breakpoints
  # slot to be sure that we update the breakpoint 
  #
  def add_loaded_file (file)
    @loaded_files[file] = true
  end

  ##
  # check whether a given file is already loaded in the debugger are stored
  #
  def check_loaded_file(file)
    @loaded_files.has_key? file
  end

  ##
  # Reset the list of files loaded in the debugger to empty
  #
  def reset_loaded_file
    @loaded_files = Hash.new
  end

  ##
  # add a watch point
  #
  def add_watchpoint(expr, gui_idx)
    @watch_mgr.add(expr,gui_idx)
  end

  ##
  # Delete a watch point
  #
  def delete_watchpoint(expr,gui_idx)
    @watch_mgr.delete(expr,gui_idx)
  end


  ##
  # Run debugger up to where the cursor is. The only way to do this is
  # to place a temporary breakpoint on the targeted line. Using "next nnn"
  # command is not possible because it count down only executable lines
  #
  def run_to_cursor
    line = cursor_line()
    return if line == @line
    file = @plugin['/system/ui/current/EditPane'].data
    @brk_mgr.add(file, line, true)
    send_command('cont')
  end

  ##
  # Make the edit pane and line where the execution point
  # is visible
  #
  def show_exec_point
    show_debugline(@file,@line)
  end

  ##
  # Pause the remote debugger
  #
  def pause
    return if @paused
    # - does not work when on a endless loop that is one line of Ruby
    #@debuggee.signal("INT")

    # catch exception in case process already killed
    begin
      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
	Process.kill(-2, @pid)
      else
	Process.kill("INT", @pid)
      end
    rescue
      puts "Exception raised while sending KILLINT to process #{@pid}\n#{$!}"
    end
    @paused = true
  end

  ##
  # Resume the remote debugger
  #
  def resume
    @paused = false
    clear_debugline(@file) # clear debug line...
    clear_debugline(@file,true) # ...and error line marker
    send_command('cont')
  end

  ##
  # Check if the remote debugger session is paused waiting
  # for a new command
  #
  #  Return:: [Boolean] true if it debugger paused
  #
  def paused?
    @paused
  end


  ##
  #  Check if the debugger session is running
  #
  #  Return:: [Boolean] true if it's running
  #
  def running?
    running
  end
   

  ##
  #  Show the debugger. Actually relay to the renderer
  #
  #  Return:: none
  #
  def show
    @actions['show'].invoke
  end

  ## 
  # Clear the console ouput
  def clear
    @actions['clear'].invoke
  end

  ##
  # send a command to the remote debugger
  def send_command(cmd)
    @plugin.log_info << "Debug command: #{cmd}"
    @action_queue.push(cmd)
    @t.run if @t && @t.status
  end

  ##
  # Originally called by the remote debugger to print the debugger prompt and
  # wait for the next end user command typed on the keyboard. In the FreeRIDE
  # version it simply waits for the next debugger command 
  #  
  def prompt( str )

    @paused = true
    update_thread_list()
    update_frame_list()
    update_local_variables()
    update_global_variables()

    # The pipe approach doesn't work on Windows, so use the
    # more portable Thread approach and suspend the Drb sub thread
    # It'll be awaken by the send_command method
    #
    @t = Thread.current
    Thread.stop if @action_queue.empty?     
    @action = @action_queue.pop

    # some special cases that are not debugger command
    case @action
      when 'CLOSE'
        @cmd = 'quit'
      else
        @cmd = @action
    end

    # @plugin.log_info << "Sending command to debugger: #{@cmd}"
    @paused = false
    return @cmd+"\n"
  end

  ##
  # Display Exception stack trace. This is called from the debuggee
  # whenever an exception is caught
  #
  def printf_excn(excn_trace, ignored)
    # TODO: In the future we should do some more clever things 
    # like allowing the user to click on each line of the stack trace
    # and follow the exception history in the various files

    # Display as if it was stderr
    if ignored
      @actions['print_stderr'].invoke(excn_trace[0].chomp+" (ignored by debugger)")
    else
      if excn_trace[0] =~ /(.*):(\d+):/ && !ignored
        prev_file = @file
        @file = $1
        @line = $2.to_i
        puts "File: #{@file}, line: #{@line}" if DEBUG
        clear_debugline(prev_file) unless prev_file == @file
        show_debugline(@file, @line, true)

        # first time we are stopping in this file? Then keep track of it
        add_loaded_file(@file) unless check_loaded_file(@file)
      end
      @actions['print_stderr'].invoke("*** Exception caught by debugger ***\n"+excn_trace.join)
    end
  end

  ##
  # This is called from the debuggee whenever a breakpoint
  # has been reached
  #
  def printf_breakpoint(idx, method, file, line)
    brkpt = @brk_mgr[idx]
    # if breakpoint is unknown to the breakpoint manager then it
    # is a temporary breakpoint
    if brkpt.nil?
      status("Breakpoint reached at cursor")
    else
      status("Breakpoint reached at #{File.basename(brkpt.file)}, line #{brkpt.line}")
    end    
  end

  ##
  # This is called from the debuggee whenever a watchpoint
  # has been reached
  #
  def printf_watchpoint(idx, method, file, line)
    expr = @watch_mgr[idx].expr
    status("Watchpoint reached at #{File.basename(file)}, line #{line} (#{expr})")
  end

  ##
  # This is called when the debugger says on which line it is (happens
  # at each step and when the debugger is pausing
  #
  def printf_line(file, line)
    prev_file = @file
    @file = file
    @line = line
    puts "File: #{@file}, line: #{@line}" if DEBUG

    clear_debugline(prev_file) unless prev_file == @file
    show_debugline(@file, @line, false)

    # first time we are stopping in this file? Then keep track of it
    add_loaded_file(@file) unless check_loaded_file(@file)
  end

  

  def printf( *args )

    # See debugger output 
    stdout.print "DBG>> " if DEBUG
    stdout.printf( *args ) if DEBUG
    
  end

  def print( *args )
    # See debugger output 
    stdout.print "DBG>> " if DEBUG
    stdout.printf( *args ) if DEBUG
  end

  ##
  # Inform the debugger that the debuggee has just loaded a new file
  # This method is called from the debuggee process
  # For now we just set up breakpoints associated with this file
  #
  def file_loaded(file)
    @brk_mgr.set_all(file)
  end

  ##
  # Update the local variable list and ask the renderer to reflect this in the UI
  #
  def update_local_variables()
    lv_info = @debuggee.fr_local_variables()
    @actions['update_local_var_list'].invoke(lv_info)    
  end

  ##
  # Update the global variable list and ask the renderer to reflect this in the UI
  #
  def update_global_variables()
    gv_info = @debuggee.fr_global_variables()
    @actions['update_global_var_list'].invoke(gv_info)    
  end

  def show_thread_list()
    th_info = @debuggee.fr_thread_list_all()
  end

  ##
  # Update the thread list and ask the renderer to reflect this in the UI
  #
  def update_thread_list()
    th_info = @debuggee.fr_thread_list_all()
    @actions['update_thread_list'].invoke(th_info)
  end

  ##
  # Select a given thread in the debugged process 
  #
  def select_thread(th_info)
    #thread_no = @debuggee.fr_select_thread(th_info[0])
    send_command("th switch #{th_info[0]}")
    #STDERR.puts "ERROR!!! selected thread #{th_info[0]} could not be selected. Now #{thread_no}" if th_info[0] != thread_no
    # after a thread change we must update the frame info
    update_frame_list()
  end

  ##
  # Format the thread info in a string (used by the renderer among other things)
  #
  def format_thread(th_info)
    "#{th_info[0]}- #{th_info[1]} #{th_info[3]} #{th_info[4]} #{File.basename(th_info[5])}:#{th_info[6]}"
  end

  ##
  # Update the frame list and ask the renderer to reflect this in the UI
  #
  def update_frame_list()
    @fr_list = @debuggee.fr_frame_list_all()
    @actions['update_frame_list'].invoke(@fr_list)
  end

  ##
  # Select a given frame in the debugged process 
  #
  def select_frame(fr_info)
    level = @debuggee.fr_select_frame(fr_info[0])
    if fr_info[0] != level
      error_msg = "ERROR!!! selected frame level #{fr_info[0]} could not be selected. Now #{level}"
      @plugin.log_error << error_msg
    else
      @file = fr_info[1]
      @line = fr_info[2].to_i
      puts "File: #{@file}, line: #{@line}" if DEBUG

      show_debugline(@file, @line)

      # first time we are stopping in this file? Then keep track of it
      add_loaded_file(@file) unless check_loaded_file(@file)

      # update the local variables view
      update_local_variables()
    end
  end

  ##
  # Format the frame info in a string (used by the renderer among other things)
  #
  def format_frame(fr_info)
    "#{fr_info[0]}- #{File.basename(fr_info[1])}:#{fr_info[2]} - #{fr_info[3]}"
  end

  ##
  # Evaluate an expression in the current context. 
  #
  # Ouput: the inspected value (not the value itself)
  def eval_expr(expr)
    # rk: remove the leading and trailing quote
    expr = @debuggee.fr_eval_expr(expr)
    expr ? expr[1..-2] : "nil"
  end

  ## 
  # Called from the remote debugger after a quit command 
  # has been received
  #
  def quit
    # before stopping the Drb server make sure the Drb thread 
    # in charge of conveying the quit call from the remote debugger
    # has its job done
    Thread.new( Thread.current ) do | th |
      while th.status == "run"
        Thread.pass
      end
      stop()
      #close() if @action == 'CLOSE'
      # do this last because it kills the thread it runs in!!
      @debugSvr.stop_service
      @debuggee = SilentDebuggee.instance
    end
  end

  private

  def stdout
    STDOUT
  end

end  # class Debugger

##
# Silent Debuggee class used whenever the
# debuggee process is stopped and we still want to 
# avoid exception if a remote method is called
class SilentDebuggee
  include Singleton
  
  def fr_eval_expr(expr)
    return '"can\'t eval - process stopped"'
  end

  def method_missing(method_id, *args)
    # capture all the missing methods and do nothing
  end
end

end; end 
