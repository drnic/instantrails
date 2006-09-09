require 'rrb/script'
require 'rrb/common_visitor'

require 'stringio'

module RRB

  class ExtractMethodVisitor < Visitor

    def initialize(start_lineno, end_lineno)
      @extracted_range = start_lineno..end_lineno
      @method_lineno = 1
      @args = []
      @assigned = []
      @target_method = nil
    end

    attr_reader :method_lineno, :args, :assigned, :target_method

    def partition_vars( vars, range )
      before_range = []; in_range = []; after_range = []
      vars.each do |id|
        before_range << id if id.lineno < range.begin
        in_range << id if range === id.lineno
        after_range << id if range.end < id.lineno
      end
      return before_range, in_range, after_range
    end

    def inspect_method( namespace, node )
      return unless node.range.contain?(@extracted_range)
      @target_method = NodeMethod.new(namespace, node)
      
      before_vars, in_vars, after_vars = partition_vars( node.local_vars,
                                                         @extracted_range )
      out_vars = before_vars + after_vars
      in_assigned = (node.assigned & in_vars)
      in_var_ref = in_vars - in_assigned
      
      @assigned = in_assigned.map{|i| i.name} & out_vars.map{|i| i.name}
      @args = before_vars.map{|i| i.name} & in_var_ref.map{|i| i.name}

      if node.name_id.name == 'toplevel'
        @method_lineno = @extracted_range.begin
      else
        @method_lineno = node.name_id.lineno
      end
    end
    
    def visit_method( namespace, node )
      inspect_method(namespace, node)
    end
    
    def visit_class_method( namespace, node )
      inspect_method(namespace, node)
    end
  end

  module_function
  def fragment_of_call_method( new_method, args, assigned )
    if assigned.empty? then
      "#{new_method.bare_name}(#{args.join(', ')})\n"
    else
      "#{assigned.join(', ')} = #{new_method.bare_name}(#{args.join(', ')})\n"
    end
  end
  
  def fragment_of_def_new_method(new_method, args )
    if new_method.instance_method?
      "def #{new_method.bare_name}(" + args.join(", ") + ")\n"
    else
      "def self.#{new_method.bare_name}(" + args.join(", ") + ")\n"
    end
  end

  def lines_of_new_method(new_method, args, assigned, extracted )
    result = reindent_lines( extracted, INDENT_LEVEL )
    result.unshift fragment_of_def_new_method( new_method, args )
    unless assigned.empty? then
      result.push " "*INDENT_LEVEL + "return " + assigned.join(", ") + "\n"
    end
    result.push "end\n"
  end
  
  def extract_method(src, new_method, start_lineno, end_lineno, method_lineno, args, assigned)
    dst = ''

    lines = src.split(/^/)

    extracted = lines[start_lineno..end_lineno]
    def_space_num =  count_indent_str( lines[method_lineno] ) 
    
    0.upto(lines.length-1) do |lineno|
      if lineno == method_lineno
        lines_of_def = lines_of_new_method( new_method, args, assigned, extracted )
        dst << reindent_lines( lines_of_def, def_space_num ).join
      end
      if lineno == end_lineno
        dst << "\s" * count_indent( extracted )
        dst << fragment_of_call_method( new_method, args, assigned )
      end
      unless (start_lineno..end_lineno) === lineno
        dst << lines[lineno]
      end
    end
    dst
  end

  class ScriptFile
    def extract_method(str_new_method, start_lineno, end_lineno)
      visitor = ExtractMethodVisitor.new(start_lineno, end_lineno) 
      @tree.accept( visitor )
      
      target_method = visitor.target_method
      new_method = target_method.method_factory.new(target_method.namespace,
                                                    str_new_method)
      
      @new_script = RRB.extract_method( @input, new_method,
                                        start_lineno-1, end_lineno-1,
                                        visitor.method_lineno-1,
                                        visitor.args, visitor.assigned)
    end
  end

  class Script    
    def extract_method(path, new_method, start_lineno, end_lineno)
      @files.each do |scriptfile|
	next unless scriptfile.path == path
	scriptfile.extract_method(new_method, start_lineno, end_lineno )
      end
    end

    def extract_method?(path, new_method, start_lineno, end_lineno)
      unless RRB.valid_method?( new_method )
        @error_message = "#{new_method} is not a valid name for methods"
        return false
      end

      method = get_method_on_region(path, start_lineno..end_lineno)
      namespace = get_class_on_region(path, start_lineno..end_lineno)

      unless namespace && method
        @error_message = "please select statements"
        return false
      end

      if get_dumped_info[namespace.name].has_method?(new_method)
        @error_message = "#{new_method}: already defined at #{namespace.name}"
        return false
      end
      
      return true
    end
  end
end
