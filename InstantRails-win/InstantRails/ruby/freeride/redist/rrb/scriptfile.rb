require 'rrb/parser'
require 'rrb/default'
require 'fileutils'
require 'stringio'

module RRB

  class ScriptFile
    attr_reader :path, :new_script, :input, :error_message
    
    def initialize( input, path )
      @input = input 
      @path = path
      @tree = Parser.new.run( input )
      @new_script = nil
      @error_message = ""
    end
    
    def write_source_to( dir )
      filepath = File.join( dir,@path.delete(':') )
      FileUtils.mkdir_p( File.dirname( filepath ) )
      File.open(  filepath , "w" ) do |file|
        file << @input
      end
    end

    def result_to_io( dst )
      return if @new_script.nil?
      dst << @path
      dst << IO_SPLITTER
      dst << @new_script
      dst << IO_SPLITTER
    end

    def result_rewrite_file
      return if @new_script.nil?
      File.open( @path, "w+" ) do |f|
	f << @new_script
      end
    end
  end


  Replacer = Struct.new( :lineno, :pointer, :before, :after )
  def Replacer.new_from_id( id, after )
    new( id.lineno, id.pointer, id.name, after )
  end
  
  # guard object 
  Guard = Object.new
  def Guard.lineno
    -1
  end
  
  module_function
  
  def replace_str( input, replace_info )
    return nil if replace_info.empty?
    
    src = StringIO.new( input )
    sorted_info = replace_info.sort_by{|i| [ i.lineno, -i.pointer ] }
    sorted_info << Guard
    
    info_index = 0
    dst = ''
    line = src.gets
    
    while line 
      
      if src.lineno == sorted_info[info_index].lineno then
	info = sorted_info[info_index]

	line[ info.pointer-info.before.size, info.before.size ] = info.after
	info_index += 1
      else
	dst << line
	line = src.gets
      end
      
    end

    return dst
  end

  def insert_str(src, insert_lineno, delete_range, insert_str)
    return nil if insert_lineno == nil && delete_range == nil
    
    dst = ''
    lines = src.split(/^/)

    0.upto(lines.length - 1) do |lineno|
      if insert_lineno && lineno == insert_lineno - 1
        dst << insert_str
        next if /^\s*$/ =~ lines[lineno]
      end
      if delete_range
        unless (delete_range.head.lineno-1..delete_range.tail.lineno-1) === lineno
          dst << lines[lineno]
        end
      else
        dst << lines[lineno]
      end
    end
    dst
    
  end

  Keywords = [ "__LINE__","__FILE__","BEGIN","END","alias","and","begin","break","case","class","def","defined?","do","else","elsif","end","ensure","false","for","if","in","module","next","nil","not","or","redo","rescue","retry","return","self","super","then","true","undef","unless","until","when","while","yield" ]

  def keyword?( id )
    Keywords.include?( id )
  end
  
  def valid_local_var?( id )
    /^[a-z_][a-zA-Z0-9_]*$/ =~ id && !keyword?( id )
  end

  def valid_instance_var?( id )
    /^@[a-zA-Z0-9_]+$/ =~ id && !keyword?( id )
  end

  def valid_class_var?( id )
    /^@@[a-zA-Z0-9_]+$/ =~ id && !keyword?( id )
  end

  def valid_global_var?( id ) 
    /^\$[a-zA-Z0-9_]+$/ =~ id && !keyword?( id )
  end

  def valid_const?( id )
    /^[A-Z][a-zA-Z0-9_]*$/ =~ id && !keyword?( id )
  end
 
  def valid_method?( id )
    /^[a-z_][a-zA-Z0-9_]*[!?]?$/ =~ id && !keyword?( id )
  end

  def space_width( str )
    result = 0
    str.each_byte do |c|
      if c == ?\t then
        result = (result/TAB_WIDTH + 1)*TAB_WIDTH
      else
        result += 1
      end
    end
    result
  end

  def count_indent_str( str )
    if /\A(\s*)/.match(str)
      space_width($1)
    else
      0
    end
  end
  
  def expand_tabs( str )
    /\A([\t ]*)((|[^\t ].*)\n?)\z/ =~ str
    " " * space_width($1) + $2
  end

  def count_indent( lines )
    return 0 if lines.empty?
    return count_indent( lines[1..-1] ) if /\A(\s*)\Z/ =~ lines[0]
    count_indent_str( lines[0] )
  end

  def delete_indent( lines )
    level = count_indent( lines )
    lines.map{|line| expand_tabs(line)[level..-1] || ""}
  end
  
  def reindent_lines( lines, level )
    delete_indent( lines ).map{|line| " "*level + line}
  end

  def reindent_lines_node( lines, node )
    return lines if node == nil
    reindent_lines( lines, node.range.head.head_pointer + INDENT_LEVEL )
  end

  def reindent_str_node( str, node )
    reindent_lines_node( str.split(/^/), node ).join
  end
  
end
