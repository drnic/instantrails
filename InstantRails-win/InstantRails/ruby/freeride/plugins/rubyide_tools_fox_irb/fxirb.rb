#! /usr/bin/env ruby

# TODO
# - handle user input redirection
# - readline

# Credits:
# - Initial linux version:  Gilles Filippini
# - Initial windows port : Marco Frailis
# - Currently maintained and developed by 
#     Martin DeMello <martindemello@gmail.com>

require "fox12"
require "irb"
require "singleton"
require "English"

include Fox

STDOUT.sync = true

class FXIRBInputMethod < IRB::StdioInputMethod

	attr_accessor :print_prompt

  def initialize
    super 
    @history = 1
		@begin = nil
	  @print_prompt = true
		@end = nil
		@continued_from = nil
  end

  def gets 

		if (a = @prompt.match(/(\d+)[>*]/))
			level = a[1].to_i
		else
			level = 0
		end

		if level > 0
			@continued_from ||= @line_no
		elsif @continued_from
			merge_last(@line_no-@continued_from+1)
			@continued_from = nil
		end
		
		if @print_prompt
			print @prompt
		
			#indentation
			print "  "*level
		end

    str = FXIrb.instance.get_line

		@line_no += 1
		@history = @line_no + 1
		@line[@line_no] = str

		str
  end

	# merge a block spanning several lines into one \n-separated line
	def merge_last(i)
		return unless i > 1
		range = -i..-1
		@line[range] = @line[range].map {|l| l.chomp}.join("\n")
		@line_no -= (i-1)
		@history -= (i-1)
	end

  def prevCmd
    if @line_no > 0
      @history -= 1 unless @history <= 1
      return line(@history)
    end
    return ""
  end

  def nextCmd
    if (@line_no > 0) && (@history < @line_no)
      @history += 1
      return line(@history)
    end
    return ""
  end

end

module IRB

  def IRB.start_in_fxirb(im)
    if RUBY_VERSION < "1.7.3"
      IRB.initialize(nil)
      IRB.parse_opts
      IRB.load_modules
    else
      IRB.setup(nil)
    end

    irb = Irb.new(nil, im)    

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context
    trap("SIGINT") do
      irb.signal_handle
    end
    
    catch(:IRB_EXIT) do
      irb.eval_input
    end
    print "\n"
  end

end

class FXIrb < FXText
	include Singleton
	include Responder

	attr_reader :input

	def FXIrb.init(p, tgt, sel, opts)
		unless @__instance__
			Thread.critical = true
			begin
				@__instance__ ||= new(p, tgt, sel, opts)
			ensure
				Thread.critical = false
			end
		end
		return @__instance__
	end

	def initialize(p, tgt, sel, opts)
		FXMAPFUNC(SEL_KEYRELEASE, 0, "onKeyRelease")
		FXMAPFUNC(SEL_KEYPRESS, 0, "onKeyPress")
		FXMAPFUNC(SEL_LEFTBUTTONPRESS,0,"onLeftBtnPress")
		FXMAPFUNC(SEL_MIDDLEBUTTONPRESS,0,"onMiddleBtnPress")
		FXMAPFUNC(SEL_LEFTBUTTONRELEASE,0,"onLeftBtnRelease")

		super
		setFont(FXFont.new(FXApp.instance, "lucida console", 9))
		@anchor = 0
	end

	def create
		super
		setFocus
		# IRB initialization
		@inputAdded = 0
		@input = IO.pipe
		$DEFAULT_OUTPUT = self

		@im = FXIRBInputMethod.new
		@irb = Thread.new {
                    while true do
			ret = IRB.start_in_fxirb(@im); STDOUT.flush; STDERR.flush
                        self.crash(ret)
                    end
		}

		@multiline = false
		
		@exit_proc = lambda {exit}
	end
	
	def on_exit(&block)
		@exit_proc = block
	end

	def crash(ret)
                #appendText("\nIRB exited abnormally. Restarting...\n\n")
                # For some reason the call below crashes when the call
                # is passed from FreeRIDE. So insert the code here
                # TODO: fix the problem (thread related??) and find a way
                # to make a distinction between normal "exit" and exit on
                # a syntax error (didn't find how to catch and print error msg)
                # see FR bug #4574
		#instance_eval(&@exit_proc)
                appendText("#{$!}\nIRB exited. Restarting...\n\n")
	end

	def onKeyRelease(sender, sel, event)
		case event.code
		when Fox::KEY_Return, Fox::KEY_KP_Enter
			newLineEntered
		end
		return 1
	end

	def onKeyPress(sender,sel,event)
		case event.code
		when Fox::KEY_Return, Fox::KEY_KP_Enter
			setCursorPos(getLength)
			super
		when Fox::KEY_Up,Fox::KEY_KP_Up
			str = extractText(@anchor, getCursorPos-@anchor)
			if str =~ /\n/
				@multiline = true
				super
				setCursorPos(@anchor+1) if getCursorPos < @anchor
			else
				history(:prev) unless @multiline
			end
		when Fox::KEY_Down,Fox::KEY_KP_Down
			str = extractText(getCursorPos, getLength - getCursorPos)
			if str =~ /\n/
				@multiline = true
				super
			else
				history(:next) unless @multiline
			end
		when Fox::KEY_Left,Fox::KEY_KP_Left
			if getCursorPos > @anchor
				super
			end
		when Fox::KEY_Delete,Fox::KEY_KP_Delete,Fox::KEY_BackSpace
			if getCursorPos > @anchor
				super
			end
		when Fox::KEY_Home, Fox::KEY_KP_Home
			setCursorPos(@anchor)
		when Fox::KEY_End, Fox::KEY_KP_End
			setCursorPos(getLength)
		when Fox::KEY_Page_Up, Fox::KEY_KP_Page_Up
			history(:prev)
		when Fox::KEY_Page_Down, Fox::KEY_KP_Page_Down
			history(:next)
		when Fox::KEY_bracketright
			#auto-dedent if the } or ] is on a line by itself
			if (emptyline? or (getline == "en")) and indented?
				dedent
			end
			super
		when Fox::KEY_u
			if (event.state & CONTROLMASK) != 0 
				str = extractText(getCursorPos, getLength - getCursorPos)
				rmline
				appendText(str)
				setCursorPos(@anchor)
			end
			super
		when Fox::KEY_k
			if (event.state & CONTROLMASK) != 0
				str = extractText(@anchor, getCursorPos-@anchor)
				rmline
				appendText(str)
				setCursorPos(getLength)
			end
			super
		when Fox::KEY_d
			if (event.state & CONTROLMASK) != 0
				#Ctrl - D
			  rmline
				appendText("exit")
				newLineEntered
			else
				# test for 'end' so we can dedent
				if (getline == "en") and indented?
					dedent
				end
			end
			super
		else
			super
		end
	end

	def dedent
		str = getline
		@anchor -= 2
		rmline
		appendText(str)
		setCursorPos(getLength)
	end

	def history(dir)
		str = (dir == :prev) ? @im.prevCmd.chomp : @im.nextCmd.chomp
		if str != ""
			removeText(@anchor, getLength-@anchor)
			write(str)
		end	
	end

	def getline
		extractText(@anchor, getLength-@anchor)
	end

	def rmline
		str = getline
		removeText(@anchor, getLength-@anchor)
		str
	end

	def emptyline?
		getline == ""
	end

	def indented?
		extractText(@anchor-2, 2) == "  "
	end

	def onLeftBtnPress(sender,sel,event)
		@store_anchor = @anchor
		setFocus
		super
	end

	def onLeftBtnRelease(sender,sel,event)
		super
		@anchor = @store_anchor
		setCursorPos(@anchor)
		setCursorPos(getLength)
	end

	def onMiddleBtnPress(sender,sel,event)
		pos=getPosAt(event.win_x,event.win_y)
		if pos >= @anchor
			super
		end
	end

	def newLineEntered
		processCommandLine(extractText(@anchor, getLength-@anchor))
	end

	def processCommandLine(cmd)
		@multiline = false
		lines = cmd.split(/\n/)
		lines.each {|i| 
			@input[1].puts i
			@inputAdded += 1
		}
		@im.print_prompt = false
		while (@inputAdded > 0) do
			@irb.run
		end
		@im.merge_last(lines.length)
		@im.print_prompt = true 
	end

	def sendCommand(cmd)
		setCursorPos(getLength)
		makePositionVisible(getLength) unless isPosVisible(getLength)
		cmd += "\n"
		appendText(cmd)
		processCommandLine(cmd)
	end

	def write(obj)
		str = obj.to_s
		appendText(str)
		setCursorPos(getLength)
		makePositionVisible(getLength) unless isPosVisible(getLength)
		return str.length
	end

	def get_line
		@anchor = getLength
		if @inputAdded == 0
			Thread.stop
		end
		@inputAdded -= 1
		return @input[0].gets
	end
end

# Stand alone run
if __FILE__ == $0
	application = FXApp.new("FXIrb", "ruby")
	application.threadsEnabled = true
	Thread.abort_on_exception = true
	application.init(ARGV)
	window = FXMainWindow.new(application, "FXIrb", nil, nil, DECOR_ALL, 0, 0, 580, 500)
	fxirb = FXIrb.init(window, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP|TEXT_SHOWACTIVE)
	application.create
	window.show(PLACEMENT_SCREEN)
	fxirb.on_exit {exit}
	application.run
end
