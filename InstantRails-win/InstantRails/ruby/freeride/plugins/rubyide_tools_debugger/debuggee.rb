# debuggee.rb
#
# $Id: debuggee.rb,v 1.13 2004/11/20 21:10:39 ljulliar Exp $
# Copyright (c) 2000 NAKAMURA, Hiroshi
#
# debuggee.rb is copyrighted free software by NAKAMURA, Hiroshi.
# You can redistribute it and/or modify it under the same term as Ruby.
#
# Many part of debuggee.rb is copied from debug.rb in ruby 1.6.7 and recycled.
# Those part is copyrighted by its authors.
#
# Upgraded to debug.rb from Ruby 1.6.7 (debug 1.20.2.5) by Laurent JULLIARD

# debug.rb
#
# Copyright (C) 2000  Network Applied Communication Laboratory, Inc.
# Copyright (C) 2000  Information-technology Promotion Agency, Japan

require 'tracer'

class Tracer
  def Tracer.trace_func(*vars)
    Single.trace_func(*vars)
  end
end

# FreeRIDE must always intercept exits hence the exit! redefinition
# at_exit calls the quit method to cleanly disconnect from the 
# FreeRIDE debugger client
module Kernel
  alias_method :exit!, :exit
end

BEGIN {
  at_exit do
    set_trace_func nil
    DEBUGGER__.quit
  end
}


SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__


###
# Redefine the DRb run method to mark all DRb threads with 
# a 'hidden' flag so they are not taken into account in the debugging
# process
# (drb is included directly from the command line to avoid a -I option
# pointing to the FR redist directory that could interfere with the include
# pathes of the debugged process.
#
module DRb
 class DRbServer

   # We need to override the run method to mark the Drb threads
   # with a special name so that they remain hidden from the user
   # view
   if DRb.const_defined? "DRbMessage"

     # we are using DRb 2.0.x
     def run
       top_th = Thread.start do
	 begin
	   while true
	     sub_th = main_loop
	     sub_th[:__debugger_hidden__] = true
	     sub_th
	   end
	 ensure
	   @protocol.close if @protocol
	   kill_sub_thread
	 end
       end
       top_th[:__debugger_hidden__] = true
       top_th
     end
    
  else

    # We are using DRb 1.3
    def run
      top_th = Thread.start do
	begin
	  while true
	    sub_th = proc
	    sub_th[:__debugger_hidden__] = true
	    sub_th
	  end
	ensure
	  @soc.close if @soc
	  kill_sub_thread
	end
      end
      top_th[:__debugger_hidden__] = true
      top_th
    end

  end

 end # class DRbServer
end # module DRb


class DEBUGGER__
  class Mutex
    def initialize
      @locker = nil
      @waiting = []
      @locked = false;
    end

    def locked?
      @locked
    end

    def lock
      return if @locker == Thread.current
      while (Thread.critical = true; @locked)
	@waiting.push Thread.current
	Thread.stop
      end
      @locked = true
      @locker = Thread.current
      Thread.critical = false
      self
    end

    def unlock
      return unless @locked
      unless @locker == Thread.current
	raise RuntimeError, "unlocked by other"
      end
      Thread.critical = true
      t = @waiting.shift
      @locked = false
      @locker = nil
      Thread.critical = false
      t.run if t
      self
    end
  end
  MUTEX = Mutex.new

  class Context
    DEBUG_LAST_CMD = []

    begin
      require 'readline'
      def readline(prompt, hist)
	Readline::readline(prompt, hist)
      end
    rescue LoadError
      def readline(prompt, hist)
	STDOUT.print prompt
	STDOUT.flush
	line = STDIN.gets
	exit unless line
	line.chomp!
	line
      end
      USE_READLINE = false
    end

    def initialize
      if Thread.current == Thread.main
	@stop_next = 1
      else
	@stop_next = 0
      end
      @last_file = nil
      @last = [nil, nil]
      @file = nil
      @line = nil
      @no_step = nil
      @frames = []
      @frame_pos = 0 #LJ - for FR
      @finish_pos = 0
      @trace = false
      @catch = ["StandardError"] #LJ - for FR
      @suspend_next = false
    end

    def stop_next(n=1)
      @stop_next = n
    end

    def set_suspend
      @suspend_next = true
    end

    def clear_suspend
      @suspend_next = false
    end

    def suspend_all
      DEBUGGER__.suspend
    end

    def resume_all
      DEBUGGER__.resume
    end

    def check_suspend
      while (Thread.critical = true; @suspend_next)
	DEBUGGER__.waiting.push Thread.current
	@suspend_next = false
	Thread.stop
      end
      Thread.critical = false
    end

    def trace?
      @trace
    end

    def set_trace(arg)
      @trace = arg
    end

    def stdout
      DEBUGGER__.stdout
    end

    def break_points
      DEBUGGER__.break_points
    end

    def display
      DEBUGGER__.display
    end

    def context(th)
      DEBUGGER__.context(th)
    end

    def set_trace_all(arg)
      DEBUGGER__.set_trace(arg)
    end

    def attached?
      DEBUGGER__.attached?
    end

    def detach
      DEBUGGER__.detach
    end

    def set_last_thread(th)
      DEBUGGER__.set_last_thread(th)
    end

    def debug_eval(str, binding)
      begin
	val = eval(str, binding)
	val
      rescue StandardError, ScriptError
	at = eval("caller(0)", binding)
	stdout.printf "%s:%s\n", at.shift, $!.to_s.sub(/\(eval\):1:(in `.*?':)?/, '') #`
	for i in at
	  stdout.printf "\tfrom %s\n", i
	end
	throw :debug_error
      end
    end

    def fr_debug_eval(str, binding)
      begin
	val = eval(str, binding)
	out = val.inspect unless val.nil?
      rescue StandardError, ScriptError
	at = eval("caller(0)", binding)
	out = sprintf("%s:%s\n", at.shift, $!.to_s.sub(/\(eval\):1:(in `.*?':)?/, '')) #`
	for i in at
	  out << sprintf("\tfrom %s\n", i)
	end
      end
      out
    end

    def debug_silent_eval(str, binding)
      begin
	val = eval(str, binding)
	val
      rescue StandardError, ScriptError
	nil
      end
    end

    def var_list(ary, binding)
      ary.sort!
      for v in ary
	stdout.printf "  %s => %s\n", v, eval(v, binding).inspect
      end
    end

    def debug_variable_info(input, binding)
      case input
      when /^\s*g(?:lobal)?$/
	stdout.global_vars(global_variables)
	var_list(global_variables, binding)

      when /^\s*l(?:ocal)?$/
	var_list(eval("local_variables", binding), binding)

      when /^\s*i(?:nstance)?\s+/
	obj = debug_eval($', binding)
	var_list(obj.instance_variables, obj.instance_eval{binding()})

      when /^\s*c(?:onst(?:ant)?)?\s+/
	obj = debug_eval($', binding)
	unless obj.kind_of? Module
	  stdout.print "Should be Class/Module: ", $', "\n"
	else
	  var_list(obj.constants, obj.module_eval{binding()})
	end
      end
    end

    def debug_method_info(input, binding)
      case input
      when /^i(:?nstance)?\s+/
	obj = debug_eval($', binding)

	len = 0
	for v in obj.methods.sort
	  len += v.size + 1
	  if len > 70
	    len = v.size + 1
	    stdout.print "\n"
	  end
	  stdout.print v, " "
	end
	stdout.print "\n"

      else
	obj = debug_eval(input, binding)
	unless obj.kind_of? Module
	  stdout.print "Should be Class/Module: ", input, "\n"
	else
	  len = 0
	  for v in obj.instance_methods(false).sort
	    len += v.size + 1
	    if len > 70
	      len = v.size + 1
	      stdout.print "\n"
	    end
	    stdout.print v, " "
	  end
	  stdout.print "\n"
	end
      end
    end

    def thnum
      num = DEBUGGER__.instance_eval{@thread_list[Thread.current]}
      unless num
	DEBUGGER__.make_thread_list
	num = DEBUGGER__.instance_eval{@thread_list[Thread.current]}
      end
      num
    end

    def debug_command(file, line, id, binding)
      MUTEX.lock
      set_last_thread(Thread.current)
      unless attached?
	MUTEX.unlock
	resume_all
	return
      end
      @frame_pos = 0
      binding_file = file
      binding_line = line
      previous_line = nil
      # LJ - FR commented out
      #if (ENV['EMACS'] == 't')
      #stdout.printf "\032\032%s:%d:\n", binding_file, binding_line
      #else
      #stdout.printf "%s:%d:%s", binding_file, binding_line,
      #line_at(binding_file, binding_line)
      #end
      stdout.printf_line(binding_file, binding_line)

      @frames[0] = [binding, file, line, id]
      display_expressions(binding)
      prompt = true
      while prompt and input = readline("(rdb:%d) "%thnum(), true)
	catch(:debug_error) do
	  if input == ""
	    input = DEBUG_LAST_CMD[0]
	    stdout.print input, "\n"
	  else
	    DEBUG_LAST_CMD[0] = input
	  end

	  case input
	  when /^\s*tr(?:ace)?(?:\s+(on|off))?(?:\s+(all))?$/
	    if defined?( $2 )
	      if $1 == 'on'
		set_trace_all true
	      else
		set_trace_all false
	      end
	    elsif defined?( $1 )
	      if $1 == 'on'
		set_trace true
	      else
		set_trace false
	      end
	    end
	    if trace?
	      stdout.print "Trace on.\n"
	    else
	      stdout.print "Trace off.\n"
	    end

	  when /^\s*b(?:reak)?\s+((?:.*?+:)?.+)$/
	    pos = $1
	    if pos.index(":")
	      file, pos = pos.split(":")
	    end
	    add_break_point(file, pos) #LJ
	    stdout.printf "Set breakpoint %d at %s:%s\n", break_points.size, file, pname

	  when /^\s*wat(?:ch)?\s+(.+)$/
	    exp = $1
	    add_watch_point(exp) # LJ
	    stdout.printf "Set watchpoint %d\n", break_points.size, exp

	  when /^\s*b(?:reak)?$/
	    if break_points.find{|b| b[1] == 0}
	      n = 1
	      stdout.print "Breakpoints:\n"
	      for b in break_points
		if b[0] and b[1] == 0
		  stdout.printf "  %d %s:%s\n", n, b[2], b[3] 
		end
		n += 1
	      end
	    end
	    if break_points.find{|b| b[1] == 1}
	      n = 1
	      stdout.print "\n"
	      stdout.print "Watchpoints:\n"
	      for b in break_points
		if b[0] and b[1] == 1
		  stdout.printf "  %d %s\n", n, b[2]
		end
		n += 1
	      end
	    end
	    if break_points.size == 0
	      stdout.print "No breakpoints\n"
	    else
	      stdout.print "\n"
	    end

	  when /^\s*del(?:ete)?(?:\s+(\d+))?$/
	    pos = $1
	    unless pos
	      #LJ input = readline("Clear all breakpoints? (y/n) ", false)
	      #LJ if input == "y"
		for b in break_points
		  b[0] = false
		end
	      #LJ end
	    else
	      pos = pos.to_i
	      if break_points[pos-1]
		break_points[pos-1][0] = false
	      else
		stdout.printf "Breakpoint %d is not defined\n", pos
	      end
	    end

	  when /^\s*disp(?:lay)?\s+(.+)$/
	    exp = $1
	    display.push [true, exp]
	    stdout.printf "%d: ", display.size
	    display_expression(exp, binding)

	  when /^\s*disp(?:lay)?$/
	    display_expressions(binding)

	  when /^\s*undisp(?:lay)?(?:\s+(\d+))?$/
	    pos = $1
	    unless pos
	      input = readline("Clear all expressions? (y/n) ", false)
	      if input == "y"
		for d in display
		  d[0] = false
		end
	      end
	    else
	      pos = pos.to_i
	      if display[pos-1]
		display[pos-1][0] = false
	      else
		stdout.printf "Display expression %d is not defined\n", pos
	      end
	    end

	  when /^\s*c(?:ont)?$/
	    prompt = false

	  when /^\s*s(?:tep)?(?:\s+(\d+))?$/
	    if $1
	      lev = $1.to_i
	    else
	      lev = 1
	    end
	    @stop_next = lev
	    prompt = false

	  when /^\s*n(?:ext)?(?:\s+(\d+))?$/
	    if $1
	      lev = $1.to_i
	    else
	      lev = 1
	    end
	    @stop_next = lev
	    @no_step = @frames.size - @frame_pos
	    prompt = false

	  when /^\s*w(?:here)?$/, /^\s*f(?:rame)?$/
	    display_frames(@frame_pos)

	  when /^\s*l(?:ist)?(?:\s+(.+))?$/
	    if not $1
	      b = previous_line ? previous_line + 10 : binding_line - 5
	      e = b + 9
	    elsif $1 == '-'
	      b = previous_line ? previous_line - 10 : binding_line - 5
	      e = b + 9
	    else
	      b, e = $1.split(/[-,]/)
	      if e
		b = b.to_i
		e = e.to_i
	      else
		b = b.to_i - 5
		e = b + 9
	      end
	    end
	    previous_line = b
	    display_list(b, e, binding_file, binding_line)

	  when /^\s*up(?:\s+(\d+))?$/
	    previous_line = nil
	    if $1
	      lev = $1.to_i
	    else
	      lev = 1
	    end
	    @frame_pos += lev
	    if @frame_pos >= @frames.size
	      @frame_pos = @frames.size - 1
	      stdout.print "At toplevel\n"
	    end
	    binding, binding_file, binding_line = @frames[@frame_pos]
	    stdout.printf "#%d %s:%s\n", @frame_pos+1, binding_file, binding_line

	  when /^\s*down(?:\s+(\d+))?$/
	    previous_line = nil
	    if $1
	      lev = $1.to_i
	    else
	      lev = 1
	    end
	    @frame_pos -= lev
	    if @frame_pos < 0
	      @frame_pos = 0
	      stdout.print "At stack bottom\n"
	    end
	    binding, binding_file, binding_line = @frames[@frame_pos]
	    stdout.printf "#%d %s:%s\n", @frame_pos+1, binding_file, binding_line

	  when /^\s*fin(?:ish)?$/
	    if @frame_pos == @frames.size
	      stdout.print "\"finish\" not meaningful in the outermost frame.\n"
	    else
	      @finish_pos = @frames.size - @frame_pos
	      @frame_pos = 0
	      prompt = false
	    end

	  when /^\s*d(?:etach)?$/
	    input = readline("really detach? (y/n) ", false)
	    if input == "y"
	      detach
	      return	# Continue executing...
	    end

	  when /^\s*cat(?:ch)?(?:\s+(.+))?$/
	    if $1
	      excn = $1
	      if excn == 'off'
		@catch = nil
		stdout.print "Clear catchpoint.\n"
	      else
		@catch = excn.split(',')
		stdout.printf "Set catchpoint %s.\n", @catch
	      end
	    else
	      if @catch
		stdout.printf "Catchpoint %s.\n", @catch
	      else
		stdout.print "No catchpoint.\n"
	      end
	    end

	  when /^\s*q(?:uit)?$/
	    #LJ input = readline("Really quit? (y/n) ", false)
	    #LJ if input == "y"
	      #LJ (see at_exit) DEBUGGER__.quit
	      exit!	# exit -> exit!: No graceful way to stop threads...
	    #LJ end

	  when /^\s*v(?:ar)?\s+/
	    debug_variable_info($', binding)

	  when /^\s*m(?:ethod)?\s+/
	    debug_method_info($', binding)

	  when /^\s*th(?:read)?\s+/
	    if DEBUGGER__.debug_thread_info($', binding) == :cont
	      prompt = false
	    end

	  when /^\s*p\s+/
	    stdout.printf "%s\n", debug_eval($', binding).inspect

	  when /^\s*h(?:elp)?$/
	    debug_print_help()

	  else
	    v = debug_eval(input, binding)
	    stdout.printf "%s\n", v.inspect unless (v == nil)
	  end
	end
      end
      MUTEX.unlock
      resume_all
    end

    def debug_print_help
      stdout.print <<EOHELP
Debugger help v.-0.002b
Commands
  b[reak] [file|method:]<line|method>
                             set breakpoint to some position
  wat[ch] <expression>       set watchpoint to some expression
  cat[ch] <an Exception>     set catchpoint to an exception
  b[reak]                    list breakpoints
  cat[ch]                    show catchpoint
  del[ete][ nnn]             delete some or all breakpoints
  disp[lay] <expression>     add expression into display expression list
  undisp[lay][ nnn]          delete one particular or all display expressions
  c[ont]                     run until program ends or hit breakpoint
  s[tep][ nnn]               step (into methods) one line or till line nnn
  n[ext][ nnn]               go over one line or till line nnn
  w[here]                    display frames
  f[rame]                    alias for where
  l[ist][ (-|nn-mm)]         list program, - lists backwards
                             nn-mm lists given lines
  up[ nn]                    move to higher frame
  down[ nn]                  move to lower frame
  fin[ish]                   return to outer frame
  tr[ace] (on|off)           set trace mode of current thread
  tr[ace] (on|off) all       set trace mode of all threads
  q[uit]                     exit from debugger
  v[ar] g[lobal]             show global variables
  v[ar] l[ocal]              show local variables
  v[ar] i[nstance] <object>  show instance variables of object
  v[ar] c[onst] <object>     show constants of object
  m[ethod] i[nstance] <obj>  show methods of object
  m[ethod] <class|module>    show instance methods of class or module
  th[read] l[ist]            list all threads
  th[read] c[ur[rent]]       show current thread
  th[read] [sw[itch]] <nnn>  switch thread context to nnn
  th[read] stop <nnn>        stop thread nnn
  th[read] resume <nnn>      resume thread nnn
  p expression               evaluate expression and print its value
  h[elp]                     print this help
  <everything else>          evaluate
EOHELP
     end

    def display_expressions(binding)
      n = 1
      for d in display
	if d[0]
          stdout.printf "%d: ", n
	  display_expression(d[1], binding)
	end
	n += 1
      end
    end

    def display_expression(exp, binding)
      stdout.printf "%s = %s\n", exp, debug_silent_eval(exp, binding).to_s
    end

    def frame_set_pos(file, line)
      if @frames[0]
	@frames[0][1] = file
	@frames[0][2] = line
      end
    end

    def display_frames(pos)
      pos += 1
      n = 0
      at = @frames
      for bind, file, line, id in at
	n += 1
	break unless bind
	if pos == n
	  stdout.printf "--> #%d  %s:%s%s\n", n, file, line, id ? ":in `#{id.id2name}'":""
	else
	  stdout.printf "    #%d  %s:%s%s\n", n, file, line, id ? ":in `#{id.id2name}'":""
	end
      end
    end

    # LJ - FR
    def fr_frame_list_all
      pos = @frame_pos+1
      n = 0
      at = @frames
      fr_list = []
      for bind, file, line, id in at
	n += 1
	break unless bind
	fr_list << [n, file, line, id ? id.id2name : '' , (pos == n)]
      end
      return fr_list
    end

    # LJ - FR
    def fr_select_frame(level)
      @frame_pos = level-1
      # a bit of paranoia...
      @frame_pos = 0 if @frame_pos < 0  # at stack bottom 
      @frame_pos = @frames.size - 1 if @frame_pos >= @frames.size #at toplelel
      return @frame_pos+1
    end

    def display_list(b, e, file, line)
      stdout.printf "[%d, %d] in %s\n", b, e, file
      if lines = SCRIPT_LINES__[file] and lines != true
	n = 0
	b.upto(e) do |n|
	  if n > 0 && lines[n-1]
	    if n == line
	      stdout.printf "=> %d  %s\n", n, lines[n-1].chomp
	    else
	      stdout.printf "   %d  %s\n", n, lines[n-1].chomp
	    end
	  end
	end
      else
	stdout.printf "No sourcefile available for %s\n", file
      end
    end

    def line_at(file, line)
      lines = SCRIPT_LINES__[file]
      if lines
	return "\n" if lines == true
	line = lines[line-1]
	return "\n" unless line
	return line
      end
      return "\n"
    end

    def debug_funcname(id)
      if id.nil?
	"toplevel"
      else
	id.id2name
      end
    end

    def check_break_points(file, pos, binding, id)
      return false if break_points.empty?
      #file = File.basename(file)
      n = 1
      for b in break_points
	if b[0]
	  if b[1] == 0 and b[2] == file and b[3] == pos
	    stdout.printf_breakpoint(n, debug_funcname(id), file, pos)
	    # LJ Delete once reached if temporary breakpoints
	    delete_break_point(n) if b[4]
	    return true
	  elsif b[1] == 1
	    if debug_silent_eval(b[2], binding)
	      stdout.printf_watchpoint(n, debug_funcname(id), file, pos)
	      return true
	    end
	  end
	end
	n += 1
      end
      return false
    end

    # LJ - Added for FreeRIDE.
    def add_break_point(file,pos, temp = false)
      # LJ - commented out because the basename is not enough in case we
      # have 2 files with the same names but with distinct path
      # file = File.basename(file)
      if pos =~ /^\d+$/
	pname = pos
	pos = pos.to_i
      else
	pname = pos = pos.intern.id2name
      end
      break_points.push [true, 0, file, pos, temp]
      return break_points.size
    end

    # LJ - Added for FreeRIDE.
    def delete_break_point(idx)
      if break_points[idx-1]
	break_points[idx-1][0] = false
	return true
      else
	return false
      end
    end

    # LJ - Added for FreeRIDE.
    def add_watch_point(exp)
      break_points.push [true, 1, exp]
      return break_points.size
    end

    # LJ - Added for FreeRIDE.
    def delete_watch_point(idx)
      delete_break_point(idx)
    end

    def excn_handle(file, line, id, binding)
      excn_out = []
      excn_out << sprintf("%s:%d: `%s' (%s)\n", file, line, $!, $!.class)
      if $!.class <= SystemExit
	set_trace_func nil
	#LJ (see at_exit) DEBUGGER__.quit
	exit
      end

      if @catch and ($!.class.ancestors.find { |e| @catch.include?(e.to_s) })
	fs = @frames.size
	tb = caller(0)[-fs..-1]
	if tb
	  for i in tb
	    excn_out << sprintf("\tfrom %s\n", i)
	  end
	end
	stdout.printf_excn(excn_out,false)
	suspend_all
	debug_command(file, line, id, binding)
      else
	stdout.printf_excn(excn_out, true)
      end
    end

    def trace_func(event, file, line, id, binding, klass)
      #STDOUT.print "#{File.basename(file)}:#{line},c: #{Thread.current}/#{Thread.current.status}/#{Thread.current[:__debugger_hidden__]}, m: #{Thread.main}, svr: #{DebugSvr.thread}\n"

      ##
      # Don't step through our DRb code. the internal mechanics of the remote debugger
      # must remain invisible to the end user
      #
      # FIXME: make sure we are not going to step through code in our debuggee.rb file
      # this only happens when calling the at_exit method to finish the debugger
      # just before we reset the trace function (see at top of file) -- Don't know if there is
      # a workaround for that ??
      return if (Thread.current[:__debugger_hidden__]) || 
	(File.basename(file) == 'debuggee.rb')

      #STDOUT.print "#{event}:#{line}(fsz=#{@frames.size}, no_step=#{@no_step}, stop_next=#{@stop_next})\n"

      Tracer.trace_func(event, file, line, id, binding, klass) if trace?
      context(Thread.current).check_suspend
      @file = file
      @line = line
      case event
      when 'line'
	frame_set_pos(file, line)
	if !@no_step or @frames.size == @no_step
	  @stop_next -= 1
	elsif @frames.size < @no_step
	  @stop_next = 0		# break here before leaving...
	else
	  # nothing to do. skipped.
	end
	#LJ reverse the test here because we always want the breakpoint reached
	# message to be display. if stop_next is null *AND* there is also a break point
	# the message will never display.
	if check_break_points(file, line, binding, id) or @stop_next == 0 
	  # LJ this test doesn't make sense and cause troubles when 
	  # on a line with a recursive call and a breakpoint on it (e.g factorial)
	  # or when in a while loop with one line only inside the loop
	  #if [file, line] == @last
	  #  @stop_next = 1
	  #else
	    @no_step = nil
	    suspend_all
	    debug_command(file, line, id, binding)
	    @last = [file, line]
	  #end
	end

      when 'call'
	@frames.unshift [binding, file, line, id]
	if check_break_points(file, id.id2name, binding, id) or
	    check_break_points(klass.to_s, id.id2name, binding, id)
	  suspend_all
	  debug_command(file, line, id, binding)
	end

      when 'c-call'
	frame_set_pos(file, line)
	if id == :require and klass == Kernel
	  @frames.unshift [binding, file, line, id]
	else
	  frame_set_pos(file, line)
	end
	
      when 'c-return'
	if id == :require and klass == Kernel
	  if @frames.size == @finish_pos
	    @stop_next = 1
	    @finish_pos = 0
	  end
	  @frames.shift
	end

      when 'class'
	@frames.unshift [binding, file, line, id]

      when 'return', 'end'
	if @frames.size == @finish_pos
	  @stop_next = 1
	  @finish_pos = 0
	end
	@frames.shift

      when 'end'
	@frames.shift

      when 'raise' 
	excn_handle(file, line, id, binding)

      end
      @last_file = file
    end
  end

  trap("INT") { DEBUGGER__.interrupt }
  @last_thread = Thread::main
  @max_thread = 1
  @thread_list = {Thread::main => 1}
  @break_points = []
  @display = []
  @waiting = []
  @stdout = STDOUT
  @loaded_files = {}

  class SilentObject
    def method_missing( msg_id, *a, &b ); end
  end
  SilentClient = SilentObject.new()
  @client = SilentClient
  @attached = false

  class <<DEBUGGER__
    def stdout
      @stdout
    end

    def stdout=(s)
      @stdout = s
    end

    def display
      @display
    end

    def break_points
      @break_points
    end

    # LJ - FR
    def last_thread
      @last_thread
    end

    def prompt( str )
      @client.prompt( str )
    end

    def attach( debugger )
      unless @attached
	set_client( debugger )
	@attached = true
	interrupt
	"#{ $0 } on #{ DebugSvr.uri }"
      else
	# Does NOT support multiple debugger.
	# raise "Already attached."
	false
      end
    end

    def detach
      @attached = false
      @client.detach
      set_client( SilentClient )
    end

    ##
    # add a file to the list of files loaded by the debugger
    # LJ for FreeRIDE
    def add_loaded_file (file)
      @loaded_files[file] = true
    end
    
    ##
    # check whether a given file is already loaded in the debugger are stored
    # LJ for FreeRIDE
    def check_loaded_file(file)
      @loaded_files.has_key? file
    end

    # LJ for FreeRIDE
    def client
      @client
    end

    def set_client( debugger )
      @client = Client.new( debugger )
      DEBUGGER__.stdout = Tracer.stdout = @client
    end

    def attached?
      @attached
    end

    def quit
      #LJ flush STDOUT and ERR
      STDERR.flush; STDOUT.flush
      detach
      DebugSvr.stop_service
    end

    def waiting
      @waiting
    end

    def set_trace( arg )
      Thread.critical = true
      make_thread_list
      for th, in @thread_list
        context(th).set_trace arg
      end
      Thread.critical = false
    end

    def set_last_thread(th)
      @last_thread = th
    end

    def suspend
      Thread.critical = true
      make_thread_list
      for th, in @thread_list
	next if th == Thread.current
	context(th).set_suspend
      end
      Thread.critical = false
      # Schedule other threads to suspend as soon as possible.
      Thread.pass
    end

    def resume
      Thread.critical = true
      make_thread_list
      for th, in @thread_list
	next if th == Thread.current
	context(th).clear_suspend
      end
      waiting.each do |th|
	th.run
      end
      waiting.clear
      Thread.critical = false
      # Schedule other threads to restart as soon as possible.
      Thread.pass
    end

    def context(thread=Thread.current)
      c = thread[:__debugger_data__]
      unless c
	thread[:__debugger_data__] = c = Context.new
      end
      c
    end

    def interrupt
      context(@last_thread).stop_next
    end

    def get_thread(num)
      th = @thread_list.index(num)
      unless th
	@stdout.print "No thread ##{num}\n"
	throw :debug_error
      end
      th
    end

    def thread_list(num)
      th = get_thread(num)
      if th == Thread.current
	@stdout.print "+"
      else
	@stdout.print " "
      end
      @stdout.printf "%d ", num
      @stdout.print th.inspect, "\t"
      file = context(th).instance_eval{@file}
      if file
	@stdout.print file,":",context(th).instance_eval{@line}
      end
      @stdout.print "\n"
    end

    # LJ - FreeRIDE
    # build an array with thread info: thread num, thread objet, current?, status, thread name, file, line
    def fr_thread_list(num)
      th_info = []
      th = get_thread(num)
      th_info << num
      th_info << th.to_s
      th_info << (th == Thread.current)
      th_info << th.status
      th_info << th["name"] # thread name if defined by user    
      th_info << context(th).instance_eval{@file}
      th_info << context(th).instance_eval{@line}
      return th_info
    end
    

    def thread_list_all
      for th in @thread_list.values.sort
	thread_list(th)
      end
    end

    # LJ - FreeRIDE
    # build an array with all threads info
    def fr_thread_list_all
      make_thread_list()
      all_th_info = []
      for th in @thread_list.values.sort
	all_th_info << fr_thread_list(th)
      end
      return all_th_info
    end

    def make_thread_list
      hash = {}
      for th in Thread::list
	next if (th[:__debugger_hidden__])
	if @thread_list.key? th
	  hash[th] = @thread_list[th]
	else
	  @max_thread += 1
	  hash[th] = @max_thread
	end
      end
      @thread_list = hash
    end

    def debug_thread_info(input, binding)
      case input
      when /^l(?:ist)?/
	make_thread_list
	thread_list_all

      when /^c(?:ur(?:rent)?)?$/
	make_thread_list
	thread_list(@thread_list[Thread.current])

      when /^(?:sw(?:itch)?\s+)?(\d+)/
	make_thread_list
	th = get_thread($1.to_i)
	if th == Thread.current
	  @stdout.print "It's the current thread.\n"
	else
	  thread_list(@thread_list[th])
	  context(th).stop_next
	  th.run
	  return :cont
	end

      when /^stop\s+(\d+)/
	make_thread_list
	th = get_thread($1.to_i)
	if th == Thread.current
	  @stdout.print "It's the current thread.\n"
	elsif th.stop?
	  @stdout.print "Already stopped.\n"
	else
	  thread_list(@thread_list[th])
	  context(th).suspend 
	end

      when /^resume\s+(\d+)/
	make_thread_list
	th = get_thread($1.to_i)
	if th == Thread.current
	  @stdout.print "It's the current thread.\n"
	elsif !th.stop?
	  @stdout.print "Already running."
	else
	  thread_list(@thread_list[th])
	  th.run
	end
      end
    end
  end


  class Context
    def readline( prompt, hist )
      DEBUGGER__.prompt( prompt )
    end
  end

  ##
  #  DEBUGGEE   ->  DRB  ->  FreeRIDE
  # The Client class holds all the methods invoked from the debuggee and executed in the
  # FreeRIDE context. Method invocation goes over DRb, is executed in FreeRIDE
  # and returns to the debuggee
  #
  class Client
    def initialize( debugger )
      @debugger = debugger
    end

    def prompt( str )
      @debugger.prompt( str )
    end

    def detach
      @debugger.quit
    end

    def printf( *args )
      @debugger.printf( *args )
    end

    def printf_line(file,line)
      @debugger.printf_line(file,line)
    end
      
    def printf_excn(excn_trace, ignored)
      @debugger.printf_excn(excn_trace, ignored)
    end

    def printf_breakpoint(n, funcname, file, line)
      @debugger.printf_breakpoint(n, funcname, file, line)
    end

    def printf_watchpoint(n, funcname, file, line)
      @debugger.printf_watchpoint(n, funcname, file, line)
    end

    def print( *args )
      @debugger.print( *args )
    end

    def global_vars(gv)
      @debugger.global_vars(gv)
    end

    def file_loaded(file)
      @debugger.file_loaded(file)
    end
  end

  ##
  #  FreeRIDE  ->  DRB  ->  DEBUGGEE 
  # The Front class holds all the methods invoked from FreeRIDE to collect information
  # from the debugged process. Method invocation goes over DRb, is executed in the
  # context of the debugger and returned to FreeRIDE.
  #
  class Front
    include DRbUndumped

    def attach( debugger )
      DEBUGGER__.attach( debugger )
    end

    def signal( type )
      case type
      when 'INT'
	DEBUGGER__.interrupt
      else
	Process.kill( type, Process.pid )
      end
    end

    # LJ - FreeRIDE
    def get_break_points()
      DEBUGGER__.break_points
    end

    # LJ - FreeRIDE
    def add_break_point(file,line, temp = false)
      return DEBUGGER__.context.add_break_point(file, line.to_s, temp)
    end

    # LJ - FreeRIDE
    def delete_break_point(pos)
      return DEBUGGER__.context.delete_break_point(pos)
    end

    # LJ - FreeRIDE
    def add_watch_point(exp)
      return DEBUGGER__.context.add_watch_point(exp)
    end

    # LJ - FreeRIDE
    def delete_watch_point(pos)
      return DEBUGGER__.context.delete_watch_point(pos)
    end
   
    # LJ - FreeRIDE
    def fr_thread_list_all()
      return DEBUGGER__.fr_thread_list_all
    end

    # LJ - FreeRIDE
    def fr_frame_list_all()
      return DEBUGGER__.context(DEBUGGER__.last_thread).fr_frame_list_all
    end

    # LJ - FreeRIDE
    def fr_select_frame(index)
      return DEBUGGER__.context(DEBUGGER__.last_thread).fr_select_frame(index)
    end

    # LJ - FreeRIDE
    def fr_local_variables()
      lv_ary = {}
      binding, file, line, id = DEBUGGER__.context(DEBUGGER__.last_thread).current_frame
      for v in eval("local_variables", binding)
	lv_ary[v] = eval(v, binding).inspect
      end
      lv_ary
    end

    # LJ - FreeRIDE
    def fr_global_variables()
      gv_ary = {}
      binding, file, line, id = DEBUGGER__.context(DEBUGGER__.last_thread).current_frame
      global_variables.each { |v| gv_ary[v] = eval(v, binding).inspect }
      gv_ary
    end

    # LJ - FreeRIDE
    def fr_eval_expr(expr)
      binding, file, line, id = DEBUGGER__.context(DEBUGGER__.last_thread).current_frame
      v = DEBUGGER__.context(DEBUGGER__.last_thread).fr_debug_eval(expr,binding)
      return v
    end

    
end
 
  # LJ - FreeRIDE
  class Context
    def current_frame
      @frames[@frame_pos]
    end
  end
  
  # LJ - On Windows redirect STDERR to STDOUT because there is
  # no popen3 call available on mswin32
  #if RUBY_PLATFORM =~ /(mswin32|mingw32)/
    STDERR.reopen(STDOUT)
  #end

  #LJ - Give a name to the main Thread
  Thread.main["name"] = 'Main'

  # LJ - forces STDERR and STDOUT to synchronize mode (FreeRIDE)
  STDERR.sync=true
  STDOUT.sync=true

  DebugSvr = DRb.start_service( nil, Front.new() )
  #STDOUT.print "#{DebugSvr.uri},#{Process.pid}\n"
  File.open(ARGV.pop,"w") { |file| file.print "#{DebugSvr.uri},#{Process.pid}\n" }

  while not attached?
    sleep 1
  end

  stdout.printf "Debug.rb\n"
  stdout.printf "Emacs support available.\n\n"

  set_trace_func proc { |event, file, line, id, binding, klass, *rest|

    # LJ make sure the file path is always absolute. It is needed by
    # the Debugger plugin in FreeRIDE and can only be determined here
    # in the context of the debugged process
    file = File.expand_path(file)

    # if file is loaded for the first time then ask our client FreeRIDE to set
    # all the breakpoints
    if (!DEBUGGER__.check_loaded_file(file))
      	DEBUGGER__.add_loaded_file(file)
	DEBUGGER__.client.file_loaded(file)
    end

    DEBUGGER__.context.trace_func event, file, line, id, binding, klass
  }
end
