# Purpose: Run ruby script and show output
#
# $Id: script_runner.rb,v 1.33 2006/06/04 09:59:02 jonathanm Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Rich Kilmer All rights reserved.
# Modified by L. Julliard 2003, 2004
#

#require 'win32_popen' if RUBY_PLATFORM =~ /(mswin32|mingw32)/
require "find"

module FreeRIDE
  class ScriptRunner
    extend FreeBASE::StandardPlugin
    include Fox

    def self.start(plugin)
      @plugin = plugin
      @@script_runner = nil
      # Handle icons
      plugin['/system/ui/icons/ScriptRunner'].subscribe do |event, slot|
        if event == :notify_slot_add
          app = plugin['/system/ui/fox/FXApp'].data
          path = "#{plugin.plugin_configuration.full_base_path}/icons/#{slot.name}.png"
          if FileTest.exist?(path)
            slot.data = Fox::FXPNGIcon.new(app, File.open(path, "rb").read)
            slot.data.create
          end
        end
      end
      cmd_mgr = plugin["/system/ui/commands"].manager

      cmd_run = cmd_mgr.add("App/Run/RunScript","&Run") do |cmd_slot|
        @@script_runner.kill if @@script_runner
        ep = plugin["/system/ui/current/EditPane"]
        prj = plugin["/project"].manager.get_project_for_editpane(ep)
        @@script_runner = ScriptRunner.new(prj)
      end
      plugin["/system/ui/keys"].manager.bind("App/Run/RunScript", :F5)

      # Make run command available at start time only if there is an edit 
      # pane opened
      cmd_run.availability = plugin['/system/ui/current'].has_child?('EditPane')
      cmd_run.icon = "/system/ui/icons/ScriptRunner/run"
      plugin["/system/ui/current/ToolBar"].manager.add_command("Run", "App/Run/RunScript")

      cmd_run.manage_availability do |command|
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

      # now set up the stop icon and menu item
      cmd_stop = cmd_mgr.add("App/Run/StopScript","&Stop") do |cmd_slot|
        @@script_runner.kill if @@script_runner
      end
      plugin["/system/ui/keys"].manager.bind("App/Run/StopScript", :ctrl, :F2)

      cmd_stop.icon = "/system/ui/icons/ScriptRunner/stop"
      plugin["/system/ui/current/ToolBar"].manager.add_command("Run", "App/Run/StopScript")
     

      cmd_clear = cmd_mgr.add("App/Run/ClearOutput","&Clear Output") do |cmd_slot|
        # FIXME: this is a hack to clear the script runner output
        # AND the debugger output. Ideally it should apply only to the
        # currently visible pane but it's not that easy to do.
        plugin["/system/ui/current/OutputPane"].manager.clear("Run")
        ep_slot = plugin["/system/ui/current/EditPane"]
        ep_slot['actions/clear_errorline'].invoke
        
        dbg = plugin["/system/ui/current/Debugger"]
        dbg.manager.clear() if dbg.is_link_slot?
      end
      plugin["/system/ui/keys"].manager.bind("App/Run/ClearOutput", :ctrl, :F5)
      cmd_clear.icon = "/system/ui/icons/ScriptRunner/clear"
      plugin["/system/ui/current/ToolBar"].manager.add_command("Run", "App/Run/ClearOutput")
      
      
      # Insert the inspector in the Tools menu
      runmenu = plugin["/system/ui/components/MenuPane/Run_menu"].manager
      runmenu.add_command("App/Run/RunScript")
      runmenu.add_command("App/Run/StopScript")
      runmenu.add_command("App/Run/ClearOutput")
      plugin.transition(FreeBASE::RUNNING)
    end


    # plugin should point to the project-slot of the project to run.
    # The project determines the run-settings.
    def initialize(plugin)
      @plugin = plugin["/plugins/rubyide_tools_fox_script_runner"].manager
      @dbg_plugin = plugin['/plugins/rubyide_tools_debugger'].manager
      
      @cmd_mgr = plugin["/system/ui/commands"].manager
      @setting_props = plugin.manager.properties
      @ep_slot = plugin["/system/ui/current/EditPane"]

      if @setting_props['save_before_running']
        @cmd_mgr.command("App/File/SaveAll").invoke
      else
        @ep_slot.manager.save_as if @ep_slot.manager.new?
      end
      
      @ep_slot['actions/clear_errorline'].invoke
      command = construct_run_command
      #puts "command: #{command}"
      return unless command
      
      # use a mutx to avoid calling the stop method (and hence detach_stdout)
      # from 2 concurrent places (waitpid thread and FOX input handler)
      @mutex = Mutex.new

      plugin["/system/ui/current/OutputPane"].manager.show
      plugin["/system/ui/current/OutputPane"].manager.attach_input(method(:keyboard_input))

      plugin["/system/ui/current/OutputPane"].manager.append("Run", "<CMD>>ruby #{@file}\n")
      if !@setting_props['run_in_terminal'] && RUBY_PLATFORM =~ /(mswin32|mingw32)/
	plugin["/system/ui/current/OutputPane"].manager.append("Run", "<CMD>*** WARNING *** Windows users should check the \"Run process in terminal\" check box in the Debugger Preferences\nto see STDOUT and STDERR output in real time.\n")
      end
      
      # run popen on both Linux and Windows. No popen3 as in the
      # debugger because it is then impossible to keep the synchronization
      # between STDOUT and STDERR output
      if RUBY_PLATFORM =~ /(mswin32|mingw32)/
        #@inp, @out = IO.win32_popen2(command,"t")
        @inp = @out = IO.popen(command,"w+")
      else
        @inp = @out = IO.popen(command,"w+")
      end

      #puts "pid = #{@out.pid}"
      #@inp.print "pid\n"
      #@pid = @out.gets.to_i # get remote process ID
      @pid = @out.pid

      t = Thread.new(@pid) { |pid|
	begin
	  Process.waitpid(pid,0)
	rescue
	  # No child processes (Errno::ECHILD) can happen if process KILLed
	ensure
	  # this little nap is necessary to avoid a fatal race condition
	  # between the detach_stdout called from here and the detach_stdout
	  # called from  attach_stdout when EOFError is raised after the 
	  # child process stopped.
	  # Note: I tried Thread.critical and mutex.synchronize in
	  # attach_stdout  and detach_stdout but it kept crashing occasionally
	  sleep 0.1
	  stop
	end
      }
      attach_stdout(@out)
      attach_stdin(@inp)

      status("Ruby Process Running (PID= #{@pid})")
      @@script_runner = self


      #begin
      #  @inp.print "go\n" # resume remote process
      #rescue
      #  cmd_mgr.command('App/Services/MessageBox').invoke('ERROR!',  'Unexpected Error while launching the script')
      #end

      @previous_trap_handler = trap("SIGINT") do
        puts "Ruby Process Interrupted (PID = #{@pid})"
        self.kill
        t.kill if t.alive?
      end
      
    end
    
    ##
    # 
    #
    def construct_run_command
      if @setting_props['run_in_terminal'] && RUBY_PLATFORM =~ /(mswin32|mingw32)/
        starter_file = File.join("#{@plugin.plugin_configuration.full_base_path}","script_starter_with_pause.rb")
      else
        starter_file = File.join("#{@plugin.plugin_configuration.full_base_path}","script_starter.rb")
      end
      
      # Get the ruby-interpreter to use
      if @setting_props['interpreter']
        int_name = @setting_props['interpreter']
        ruby_path = (@dbg_plugin.properties['interpreters'])[int_name]['command']
      else
        ruby_path = @dbg_plugin.properties['path_to_ruby'] 
      end
      unless FileTest.exist?(ruby_path)
        @cmd_mgr.command('App/Services/MessageBox').invoke("Where is Ruby?",
          "I can't find the default Ruby interpreter. Please configure the path to ruby in the Debugger/Run preference box")
        return
      end
      
      exec_args = @setting_props['cmd_line_options']
      @file = @ep_slot.manager.filename
      
      exec_dir = @setting_props['working_dir']
      exec_dir = File.expand_path(File.dirname(@file)) if (exec_dir == '' || exec_dir == nil)
      @exec_dir = exec_dir
      
      command = "#{ruby_path} -C \"#{exec_dir}\" -r \"#{starter_file}\" "
      
      if @setting_props["name"] != "Default Project"
        @setting_props["source_directories"].each do |s| command += " -I \"#{s}\"" end
        @setting_props["required_directories"].each do |r| command += " -I \"#{r}\"" end
      end
      
      command += " \"#{@file}\" #{exec_args}"
      
      if @setting_props['run_in_terminal']
        if RUBY_PLATFORM =~ /(mswin32|mingw32)/
          command = "start CMD /C "+command
        else
          command = "xterm -e '"+command+"; read -p  \"Press ENTER to close the window...\"'"
        end
      end
      command
    end

    ##
    # kill the running process
    #
    def kill
      @killed = true
      begin
        puts "Killing #{@pid}"
        Process.kill("SIGKILL", @pid)
      rescue
        # in case the process already died  - do nothing
      ensure
	stop(true)
      end
    end

    ##
    # stop the running process
    #
    def stop(killed=false)

      # if pid is nil then it means we already ran the stop method
      return if @pid.nil?

      detach_stdout(@out)
      detach_stdin(@inp)
      @out.close unless @out.closed?
      @inp.close unless @inp.closed?

      if killed
	@plugin["/system/ui/current/OutputPane"].manager.append("Run", "<CMD>>Process Interrupted!!\n")
	status("Ruby Process Interrupted (PID = #{@pid})")
      else 
	@plugin["/system/ui/current/OutputPane"].manager.append("Run", "<CMD>>exit\n")
        status("Ruby Process Exited (PID = #{@pid})")
      end

      @pid = nil
      @@script_runner = nil
      @killed = nil
      trap("SIGINT",@previous_trap_handler)

     end

    ##
    # monitor the script stdout and print any incoming text
    # to the script runner text console
    #
    def attach_stdout(fh)
      getApp().addInput(fh, INPUT_READ|INPUT_EXCEPT) do |sender, sel, ptr|
        case FXSELTYPE(sel)
        when SEL_IO_READ
          begin
            text = fh.sysread(5000)
	    print_stdout(text)
	    check_error(text)
          rescue EOFError, IOError
            detach_stdout(fh)
          end
        when SEL_IO_EXCEPT
          puts 'onPipeExcept'
        end
      end
    end
    
    ##
    # attach stdin of script to the renderer
    #
    def attach_stdin(fh)
      # Nothing to do
    end
    
    ##
    # Detach the stdout input from the text console
    #
    def detach_stdout(fh)
      unless fh.nil? || fh.closed?
	getApp().removeInput(fh, INPUT_READ|INPUT_EXCEPT)
      end
    end
    
    ##
    # Detach the stdin from the text console
    #
    def detach_stdin(fh)
      # Nothing to do
    end

    ##
    # print script stdout to text console
    #
    def print_stdout(text)
      @plugin["/system/ui/current/OutputPane"].manager.append("Run", text)
    end

    ##
    # check text output of remote process for error
    #
    def check_error(text)
      # if there is an error message then point the faulty line in the editpane
      # open the file if not already loaded in one of the Edit panes.
      # If line is nil it removes the line marker, If file is nil do nothing
      if text =~ /\s*(.*\.rb):(\d+):/
	err_file, line = $1, $2
	err_file = File.expand_path(File.join(@exec_dir,err_file)) unless File.absolute_path?(err_file)
	
	ep_slot = @cmd_mgr.command("EditPane/FindFile").invoke(err_file)
	#puts "err_file: #{err_file}, line: #{line}, ep_slot: #{ep_slot}"
	ep_slot = @cmd_mgr.command("App/File/Load").invoke(err_file) if ep_slot.nil?
	unless ep_slot.nil? # just in case file loading went wrong
	  ep_slot['actions/make_current'].invoke unless ep_slot.nil?
	  ep_slot['actions/show_errorline'].invoke(line)
	end
      end
    end

    ##
    # Return the FOX FXApp global variable
    #
    def getApp
      @plugin['/system/ui/fox/FXApp'].data
    end

    ##
    # Prompt a message in the status bar
    #
    def status(msg)
      @plugin['/system/ui/current/StatusBar/actions/prompt'].invoke(msg)
    end

    def keyboard_input(text)
      # send user input to remote process unless pipe is closed.
      unless @inp.nil? || @inp.closed?
	begin
	  if (text[0] == 13)
	    @inp.syswrite("\n")
	  else
	    @inp.syswrite(text)
	  end
	rescue
	  # rescue a possible Errno::EPIPE (linux) or invalid argument (win32)
	  # exception if the pipe was broken while we were buffering
	  # keyboard input from FOX
	end
      end
    end

  end

end
