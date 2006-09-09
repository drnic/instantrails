require 'tempfile'
require 'readline'
require 'getoptlong'
require 'curses'
require 'rrb/rrb'
require 'rrb/completion'

class String
  def trim
    split(/\s+/).find{|s| s != ""}
  end
end

module RRB
  module CUI
    USAGE = <<USG
usage: rrbcui [options] FILES..

Refactoring FILES automatically.

options:
  -w              rewrite FILES [no implementation]
  -d DIFF         output diff [default, DIFF=output.diff]
  -h              print this message and exit
  -r REFACTORING  do REFACTORING

refactoring:
  rename-local-variable [method old-var new-var]
  rename-instance-variable [class old-var new-var]
  rename-class-variable [class old-var new-var]
  rename-global-variable [old-var new-var]
  rename-constant [old-constant new-constant]
  rename-class [old-class new-class]
  rename-method-all [old-method new-method]
  rename-method [old-methods.. new-method]
  extract-method [file begin end new-method]
  extract-superclass [new-namespace new-class target-classes.. file lineno]
  pullup-method [old-class#old-method new-class file lineno]
  pushdown-method [old-class#old-method new-class file lineno]
USG

    OPTIONS = [
      ['-d', GetoptLong::REQUIRED_ARGUMENT],
      ['-w', GetoptLong::NO_ARGUMENT],
      ['--help', '-h', GetoptLong::NO_ARGUMENT],
      ['-r', GetoptLong::REQUIRED_ARGUMENT],
    ]

    REFACTORING = [
      'rename-local-variable',
      'rename-instance-variable',
      'rename-class-variable',
      'rename-global-variable',
      'rename-constant',
      'rename-class',
      'rename-method-all',
      'rename-method',
      'extract-method',
      'extract-superclass',
      'pullup-method',
      'pushdown-method',
    ]

    module_function
    def print_usage
      print USAGE
      exit
    end

    def select_one(prompt, words)
      Readline.completion_proc = Proc.new do |word|
        words.grep(/^#{Regexp.quote(word)}/)
      end
      Readline.readline(prompt).trim
    end

    # parse ARGV and do refactoring
    def execute
      print_usage if ARGV.empty?

      diff_file = 'output.diff'
      refactoring = nil

      parser = GetoptLong.new
      parser.set_options( *OPTIONS )
      parser.each_option do |name, arg|
        print_usage if name == '--help'
        diff_file = arg if name == '-d'
        refactoring = arg if name == '-r'
      end

      if File.exist?(diff_file)
        STDERR.print "ERROR: #{diff_file} exists\n"
        exit 1
      end
      
      Readline.basic_word_break_characters = "\t\n\"\\'"

      refactoring = select_one("Refactoring: ", REFACTORING) unless refactoring

      case refactoring
      when "rename-local-variable"
        ui = RenameLocalVariable.new(ARGV, diff_file)
      when "rename-instance-variable"
        ui = RenameInstanceVariable.new(ARGV, diff_file)
      when "extract-method"
        ui = ExtractMethod.new(ARGV, diff_file)
      else
        raise 'No such refactoring'
      end
      
      ui.run
    end

    # this class enables you to show file, scroll, select line
    # and select region
    class Screen
      def initialize(str)
        @str = str.split(/^/)
        @cursor = 0
        @top = 0
        @start = nil
      end

      def new_region(lineno1, lineno2)
        if lineno1 < lineno2
          lineno1+1 .. lineno2+1
        else
          lineno2+1 .. lineno1+1
        end
      end

      def select
        Curses.init_screen
        begin
          Curses.nonl
          Curses.cbreak
          Curses.noecho
          
          loop do
            draw_screen
            
            key = Curses.getch
            case key
            when ?j, ?\C-n, Curses::KEY_DOWN
              cursor_down
            when ?J
              scroll_down
            when ?k, ?\C-p, Curses::KEY_UP
              cursor_up
            when ?K
              scroll_up
            when ?\s, Curses::KEY_NPAGE
              Curses.lines.times{ scroll_down }
            when ?g
              @str.size.times{ cursor_up }
            when ?G
              @str.size.times{ cursor_down }
            when ?q
              return nil
            when ?\C-m
              yield
            end
          end
          
        ensure
          Curses.clear
          Curses.close_screen
        end
      end
      
      def select_region
        select do
          if @start
            return new_region(@start, @cursor)
          else
            @start = @cursor
          end
        end
      end

      def select_line
        select do
          return @cursor + 1
        end
      end
      
      def draw_screen
        Curses.lines.times do |i|
          break if @str[@top+i] == nil
          Curses.setpos(i, 0)
          Curses.standout if i == @start
          Curses.addstr(@str[@top+i])
          Curses.standend
        end
        Curses.setpos(@cursor - @top, 0)
        Curses.refresh
      end
      
      # scroll down the screen
      def scroll_down
        return if @str[@top+Curses.lines+1] == nil
        @top += 1
        @cursor = @top if @cursor < @top
      end
      
      def cursor_down
        return if @cursor >= @str.size - 1
        @cursor += 1
        scroll_down if @cursor - @top >= Curses.lines
      end

      # scroll up the screen
      def scroll_up
        return if @top <= 0
        @top -= 1
        @cursor = @top + Curses.lines - 1 if @cursor > @top + Curses.lines - 1
      end
      
      def cursor_up
        return if @cursor <= 0
        @cursor -= 1
        scroll_up if @cursor < @top
      end
    end
    
    class UI
      def initialize(files, diff_file)
        @script = Script.new_from_filenames(*files)
        @diff_file = diff_file
      end

      def output_diff
        system("touch #{@diff_file}")
        @script.files.find_all{|sf| sf.new_script != nil}.each do |sf|
          tmp = Tempfile.new("rrbcui")
          begin
            tmp.print(sf.new_script)
            tmp.close
            system("diff -u #{sf.path} #{tmp.path} >> #{@diff_file}")
          ensure
            tmp.close(true)
          end
        end
      end

      def select_one(prompt, words)
        CUI.select_one(prompt, words)
      end
      
      def input_str(prompt)
        Readline.completion_proc = proc{ [] }
        Readline.readline(prompt).trim
      end
  
      def select_region(scriptfile)
        Screen.new(scriptfile.input).select_region
      end
    end

    class RenameLocalVariable < UI
      def methods
        @script.refactable_methods.map{|method| method.name}
      end

      def vars(method)
        @script.refactable_methods.find{|m| m.name == method}.local_vars.to_a
      end

      def run
        method = select_one("Refactored method: ", methods)
        old_var = select_one("Old variable: ", vars(method))
        new_var = input_str("New variable: ")
        unless @script.rename_local_var?(Method[method], old_var, new_var)
          STDERR.print(script.error_message, "\n")
          exit
        end
        @script.rename_local_var(Method[method], old_var, new_var)
        output_diff
      end
    end
    
    class RenameInstanceVariable < UI
      def classes
        @script.refactable_classes
      end

      def ivars(target)
        @script.refactable_classes_instance_vars.each do |classname, cvars|
          return cvars if classname == target
        end
        return []
      end
      
      def run
        namespace = select_one("Refactared class: ", classes)
        old_var = select_one("Old variable: ", ivars(namespace))
        new_var = input_str("New variable: ")
        unless @script.rename_instance_var?(namespace, old_var, new_var)
          STDERR.print(script.error_message, "\n")
          exit
        end
        @script.rename_instance_var(namespace, old_var, new_var)
        output_diff
      end
    end

    class ExtractMethod < UI
      def files
        @script.files.map{|sf| sf.path}
      end

      def run
        path = select_one("What file?: ", files)
        region = select_region(@script.files.find{|sf| sf.path == path})
        new_method = input_str("New method: ")
        unless @script.extract_method?(path, new_method, region.begin, region.end)
          STDERR.print(script.error_message, "\n")
          exit
        end
        @script.extract_method(path, new_method, region.begin, region.end)
        output_diff
      end
    end
  end
end

if $0 == __FILE__
  exit if ARGV.empty?
  screen = RRB::CUI::Screen.new(File.read(ARGV[0]))
  p screen.select_region
end
