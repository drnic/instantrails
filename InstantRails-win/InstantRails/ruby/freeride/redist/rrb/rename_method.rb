require 'rrb/scriptfile'
require 'rrb/script'
require 'rrb/node.rb'
require 'rrb/parser.rb'

require 'set'

module RRB
  
  class RenameMethodVisitor < Visitor

    def initialize( old_methods, new_method )
      @old_methods = old_methods
      @new_method = new_method
      @result = []
    end

    attr_reader :result

    def warning_piece( namespace, num_spaces, renamed )
      old_method = renamed.bare_name
      "def #{old_method}(*arg); \
raise '#{namespace.name}##{old_method} is renamed #{@new_method}' end\n" +
	" "*num_spaces
    end

    def rename_method_def( namespace, id, head_keyword, renamed )
      @result << Replacer.new_from_id( id, @new_method )
      @result << Replacer.new( id.lineno, head_keyword.head_pointer,
			      "",
			      warning_piece( namespace,
                                             head_keyword.head_pointer,
                                             renamed ) )
    end

    def rename_fcalls( fcalls, renamed )
      fcalls.find_all(){|fcall| fcall.name == renamed.bare_name}.each do |fcall|
        @result << Replacer.new_from_id( fcall.body, @new_method )        
      end
    end
    
    def visit_method( namespace, node )

      @old_methods.each do |renamed|
        if renamed.match_node?( namespace, node )
          rename_method_def( namespace, node.name_id, node.head_keyword, renamed )
        end

        if namespace == renamed.namespace 
          rename_fcalls( node.fcalls, renamed )
        end
      end

    end

  end
    
  class GetAllClassesCallMethod < Visitor

    def initialize( methodname )
      @method = methodname
      @classes = []
    end

    attr_reader :classes
    
    def visit_method( namespace, node )
      if node.fcalls.find{|fcall| fcall.name == @method } then
	@classes << Namespace.new( namespace.name )
      end
    end

  end

  class GetAllFCallVisitor < Visitor
    def initialize
      @result = Set.new
    end

    attr_reader :result
    
    def visit_method( namespace, node )
      node.fcalls.each do |fcall|
        @result.add Method.new( namespace, fcall.name )
      end
    end
  end
  
  class Script

    def all_fcalls
      @files.inject(Set.new) do |result,scriptfile|
        result + scriptfile.all_fcalls
      end
    end
    def supermethod?( method1, method2 )
      unless get_dumped_info[method2.namespace].subclass_of?( method1.namespace )
        return false
      end
      return false unless method1.bare_name == method2.bare_name
      return true
    end

    def supermethods( method )
      get_dumped_info[method.namespace].ancestors.find_all do |ancestor|
        ancestor.has_method?( method.bare_name, false ) 
      end.map{|klass| Method.new( klass.class_name, method.bare_name ) } +
          [ method ]
    end
    
    def methods_related_with( methods )
      basis = Set.new
      methods.each do |method|
        basis.merge( supermethods(method) )
      end
      basis.merge all_fcalls.find_all{|fcall|
        methods.any?{|m| supermethod?( fcall, m )}
      }
      result = Set.new
      get_dumped_info.each do |classinfo|
        basis.each do |basemethod|
          if classinfo.subclass_of?( basemethod.namespace )
            result.add Method.new( classinfo.class_name, basemethod.bare_name )
          end
        end
      end
      result
    end
    
    def rename_method( old_methods, new_method )
      renamed_methods = methods_related_with( old_methods ).to_a
      @files.each do |scriptfile|
	scriptfile.rename_method( renamed_methods, new_method )
      end
    end

    def rename_method?(  old_methods, new_method )
      
      unless RRB.valid_method?( new_method )
        @error_message = "#{new_method} is not a valid name for methods"
        return false
      end

      old_method = old_methods.first.bare_name
      unless old_methods.all?{|m| m.bare_name == old_method}
        @error_message = "All method should be same name"
        return false
      end

      methods_related_with( old_methods ).each do |method|
        if get_dumped_info[method.namespace].has_method?( new_method )
         @error_message = "#{new_method}: already defined at #{method.namespace.name}"
	  return false
	end
      end 
      true
    end
    
  end

  class ScriptFile
    
    def rename_method( old_methods, new_method )
      visitor = RenameMethodVisitor.new(  old_methods, new_method )
      @tree.accept( visitor )
      @new_script = RRB.replace_str( @input, visitor.result )
    end

    def all_fcalls
      visitor = GetAllFCallVisitor.new
      @tree.accept( visitor )
      visitor.result
    end
    
  end
end
