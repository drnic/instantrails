require 'rrb/script'

module RRB

  class RenameLocalVarVisitor < Visitor

    def initialize( method_name, old_var, new_var )
      @method_name = method_name
      @old_var = old_var
      @new_var = new_var
      @result = []
    end

    attr_reader :result
    
    def rename_local_var(namespace, method_node)
      return unless @method_name.match_node?( namespace, method_node )
	
      method_node.local_vars.each do |id|
	if id.name == @old_var then
	  @result << Replacer.new_from_id( id, @new_var )
	end
      end
    end

    def visit_method( namespace, method_node )
      rename_local_var(namespace, method_node)
    end

    def visit_class_method(namespace, method_node)
      rename_local_var(namespace, method_node)
    end
  end

  class RenameLocalVarCheckVisitor < Visitor
    
    def initialize( method_name, old_var, new_var )
      @method_name = method_name
      @old_var = old_var
      @new_var = new_var
      @result = true
    end

    attr_reader :result

    def rename_local_var?(namespace, method_node)
      return unless @method_name.match_node?(namespace, method_node)

      if method_node.local_vars.find{|i| i.name == @new_var} then
        @error_message = "#{@new_var}: already used"
	@result = false
      end
      if method_node.fcalls.find{|i| i.name == @new_var} then
        @error_message = "#{@new_var}: already used as a function"
	@result = false
      end
    end


    def visit_method( namespace, method_node )
      rename_local_var?(namespace, method_node)
    end

    def visit_class_method(namespace, method_node)
      rename_local_var?(namespace, method_node)      
    end
    
  end

  class ScriptFile
    
    def rename_local_var( method_name, old_var, new_var )
      visitor = RenameLocalVarVisitor.new( method_name,
					  old_var, new_var )
      @tree.accept( visitor )
      @new_script = RRB.replace_str( @input, visitor.result )
    end

    def rename_local_var?( method_name, old_var, new_var )
      visitor = RenameLocalVarCheckVisitor.new( method_name,
					       old_var, new_var )
      @tree.accept( visitor )
      @error_message = visitor.error_message unless visitor.result
      return visitor.result
    end

  end

  class Script
    
    def rename_local_var( method_name, old_var, new_var )
      @files.each do |scriptfile|
	scriptfile.rename_local_var( method_name,
				    old_var, new_var )
      end
    end

    def rename_local_var?( method_name, old_var, new_var )
      unless RRB.valid_local_var?( new_var )
        @error_message = "#{new_var}: not a valid name for local variables"
        return false
      end

      if error_scriptfile = @files.find(){|scriptfile| not scriptfile.rename_local_var?( method_name, old_var, new_var ) }
        @error_message = error_scriptfile.error_message
        return false        
      end
      return true
      
    end

  end
  
end
