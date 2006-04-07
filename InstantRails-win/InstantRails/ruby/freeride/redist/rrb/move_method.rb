require 'rrb/script'

module RRB

  class MoveMethodCheckVisitor < Visitor
    
    def initialize(method_name, old_namespace, new_namespace)
      @method_name = method_name
      @str_old_namespace = old_namespace.name
      @str_new_namespace = new_namespace.name
      @result = true
    end
    
    attr_reader :result
    
    def nodes_include_the_method?(nodes)
      nodes.map{|i| i.name}.include?(@method_name)
    end
    
    def class_include_the_method?(node)
      nodes_include_the_method?(node.method_defs) || nodes_include_the_method?(node.class_method_defs) || nodes_include_the_method?(node.singleton_method_defs)     
    end

    def visit_class(namespace, node)
      str_namespace = namespace.nested( node.name ).name
      if @str_old_namespace == str_namespace
        unless class_include_the_method?(node)
          @result = false 
        end 
      end
      if @str_new_namespace == str_namespace
        if class_include_the_method?(node)
          @result = false
        end
      end
    end
  end

  class ScriptFile
    def move_method(method_name, old_namespace, new_namespace, moved_method)
      visitor = MoveMethodVisitor.new(method_name, old_namespace, new_namespace)
      @tree.accept( visitor )
      RRB.insert_str(@input, visitor.insert_lineno, visitor.delete_range, moved_method)
    end

    def move_method?(method_name, old_namespace, new_namespace)
      visitor = MoveMethodCheckVisitor.new(method_name, old_namespace, new_namespace)
      @tree.accept( visitor )
      return visitor.result
    end
  end

  class Script
    
    def move_method(method_name, old_namespace, new_namespace)
      moved_method = get_string_of_method(old_namespace, method_name)
      @files.each do |scriptfile|
	scriptfile.move_method(method_name, old_namespace, new_namespace, moved_method)
      end
    end

    def move_method?(method_name, old_namespace, new_namespace)
      @files.each do |scriptfile|
	if not scriptfile.move_method?(method_name, old_namespace, new_namespace)
          return false
	end
      end
      return true
    end
  end
end
