require 'rrb/scriptfile.rb'
require 'stringio'
require 'fileutils'
require 'find'
require 'rrb/dumped_info.rb'
require 'rrb/default'
require 'rrb/dump_modules'
require 'rbconfig'

module RRB

  IO_SPLITTER = "\C-a"
  IO_TERMINATOR = '-- END --'

  RUBY_COMMAND = Config::CONFIG['ruby_install_name']
  
  class Script

    extend Once
    
    def initialize( files )
      @files = files
      @error_message = ""
    end
    
    def result_to_io( dst )

      @files.each do |scriptfile|
	scriptfile.result_to_io( dst )
      end

      dst << IO_TERMINATOR
      dst << IO_SPLITTER
      dst << "\n"
    end

    def result_rewrite_file
      @files.each do |scriptfile|
	scriptfile.result_rewrite_file
      end
    end


    def find_dir( path )
      dirs = []
      Find.find( path ) do |filepath|
	dirs << filepath if FileTest.directory?( filepath )
      end
      dirs 
    end
    
    def mk_run_file( work_dir_path, script_dir_path )
      run_file_path = File.join( work_dir_path, 'rrb_dump.rb' )
      run_file = File.open( run_file_path, "w" )
      run_file << "require 'rrb_reflection'\n"
      run_file << "$rrb_run_for_reflection = true\n"
      run_file << DEFINE_LOAD_SCRIPT
      
      find_dir( script_dir_path ).each do |dirpath|
	run_file << "$__rrb_load_path.unshift '#{dirpath}'\n"
      end
      
      @files.each do |scriptfile|
	run_file << "__rrb_load '#{File.basename( scriptfile.path )}'\n"
      end
      run_file << DUMP_MODULES_SCRIPT
      run_file.close
      
      run_file_path
    end
    
    def get_dumped_info
      work_dir_path = RRB.mk_work_dir
      begin
	script_dir_path = File.join( work_dir_path, 'scripts' )
	@files.each do |scriptfile|
	  scriptfile.write_source_to( script_dir_path )
	end

	run_file_path = mk_run_file( work_dir_path, script_dir_path )
	
	IO.popen("#{RUBY_COMMAND} #{RUBY_OPTS} #{run_file_path}") do |io|
	  return  DumpedInfo.get_dumped_info( io ) 
	end
	if $?/256 != 0 then
           raise SDL::Error, "fail to run ruby internally"
        end
      ensure
	FileUtils.rm_r work_dir_path
      end
    end

    once :get_dumped_info
    
    def Script.new_from_io( input )

      files = []
      loop do	
	path = input.gets( IO_SPLITTER ).chop
	break if path == IO_TERMINATOR
	content = input.gets( IO_SPLITTER ).chop
	files << ScriptFile.new( content, path )
      end

      return new( files )
    end

    def Script.new_from_filenames( *filenames )
      files = []
      filenames.each do |filename|
	files << ScriptFile.new( File.read(filename), filename )
      end
      return new( files )
    end

    def Script.new_from_marshal(filename)
      return Marshal.load(File.open(filename))
    end

    attr_reader :files, :error_message
    
  end
  module_function
  
  def mk_work_dir
    
    n = 0
    loop do
      raise_exeption = false
      path = WORK_DIR_BASENAME+'.'+Process.pid.to_s+'.'+n.to_s
      begin
	Dir.mkdir( path )
      rescue Errno::EEXIST
	raise_exeption = true
      end
      return path unless raise_exeption
      n += 1
    end
    
  end
  
end
