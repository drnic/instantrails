require 'rrb/script'

module RRB

  class GetInstanceVarOwnerVisitor < Visitor
    def initialize(namespace, dumped_info, old_var)
      @old_var = old_var
      @dumped_info = dumped_info
      @my_info = dumped_info[namespace]
      @owner = namespace
    end

    attr_reader :owner
    
    def visit_method(namespace, node)
      return unless node.instance_vars.find{|i| i.name == @old_var}
      if @dumped_info[@owner].ancestor_names.include?( namespace )
        @owner = namespace
      end
    end
  end

  class RenameInstanceVarVisitor < Visitor

    def initialize( owner, dumped_info, old_var, new_var )
      @owner = owner
      @old_var = old_var
      @new_var = new_var
      @dumped_info = dumped_info
      @result = []
    end

    attr_reader :result

    
    def check_namespace(namespace)
      @dumped_info[namespace].subclass_of?(@owner)
    end

    def rename_instance_var(namespace, node)
      if check_namespace(namespace)
        node.instance_vars.find_all{|id| id.name == @old_var}.each do |id|
          @result << Replacer.new_from_id(id, @new_var)
        end
      end
    end

    def visit_method( namespace, node )
      rename_instance_var( namespace, node)
    end
  end


  class RenameInstanceVarCheckVisitor < Visitor
    
    def initialize( owner, dumped_info, old_var, new_var )
      @owner = owner
      @dumped_info = dumped_info
      @old_var = old_var
      @new_var = new_var
      @result = true
    end

    attr_reader :result

    def check_namespace(namespace)
      return @dumped_info[namespace].subclass_of?(@owner)
    end

    def rename_instance_var?(namespace, node)
      if check_namespace(namespace)
        if node.instance_vars.any?{|id| id.name == @new_var}
          @error_message = "#{@new_var}: already used by #{namespace.name}"
          return false
        end
      end
      return true
    end

    def visit_method( namespace, node )
      if !rename_instance_var?( namespace, node)
        @result = false
      end
    end
  end

  class ScriptFile

    def get_ancestral_ivar_owner( namespace, dumped_info, var )
      get_owner = GetInstanceVarOwnerVisitor.new(namespace, dumped_info, var)
      @tree.accept(get_owner)
      get_owner.owner
    end
    
    def rename_instance_var( real_owner, dumped_info, old_var, new_var )
      visitor = RenameInstanceVarVisitor.new( real_owner, dumped_info,
					  old_var, new_var )
      @tree.accept( visitor )
      @new_script = RRB.replace_str( @input, visitor.result )
    end

    def rename_instance_var?( real_owner, dumped_info, old_var, new_var )
      visitor = RenameInstanceVarCheckVisitor.new( real_owner, dumped_info,
						  old_var, new_var )
      @tree.accept( visitor )
      @error_message = visitor.error_message unless visitor.result
      return visitor.result
    end

  end

  class Script

    def get_real_ivar_owner( namespace, var )
      @files.inject( namespace ) do |owner,scriptfile|
	scriptfile.get_ancestral_ivar_owner( owner, get_dumped_info, var )
      end
    end
    
    def rename_instance_var( namespace, old_var, new_var )

      owner = get_real_ivar_owner( namespace, old_var )
      @files.each do |scriptfile|
	scriptfile.rename_instance_var( owner, get_dumped_info,
				       old_var, new_var )
      end
    end

    def rename_instance_var?( namespace, old_var, new_var )
      unless RRB.valid_instance_var?( new_var )
        @error_message = "#{new_var}: not a valid name for instance variables"
        return false
      end
      
      owner = get_real_ivar_owner( namespace, old_var )

      @files.each do |scriptfile|
        unless scriptfile.rename_instance_var?(owner, get_dumped_info,
                                               old_var, new_var)
          @error_message = scriptfile.error_message
          return false          
        end
      end
      return true
    end
  end
end
