require 'rrb/script'
require 'rrb/common_visitor'

module RRB

  class ExtractSuperclassVisitor < Visitor
    def initialize( namespace, new_class, targets )
      @new_superclass = namespace.abs_name + '::' + new_class
      @targets = targets
      @result = []
    end

    attr_reader :result
    
    def visit_class( namespace, node )
      classname = namespace.nested( node.name )
      return unless @targets.include?( classname )
      return if node.superclass == nil
      @result << Replacer.new_from_id( node.superclass.body, @new_superclass )
    end
  end
  
  class ScriptFile
    
    def extract_superclass( namespace, new_class, targets )
      visitor = ExtractSuperclassVisitor.new( namespace, new_class, targets )
      @tree.accept( visitor )      
      @new_script = RRB.replace_str( @input, visitor.result )
    end

    def add_superclass_def( lines, lineno )
      indented = RRB.reindent_lines_node( lines, class_node_on( lineno ) ).join
      @new_script = RRB.insert_str( @new_script, lineno, nil, indented )
    end

  end
  
  class Script
    
    def superclass_def( namespace, new_class, old_superclass, where )
      result = [
        "class #{new_class} < ::#{old_superclass.name}\n",
        "end\n"
      ]

      ns = namespace
      until ns == where
        result = RRB.reindent_lines( result, INDENT_LEVEL )
        result.unshift( "#{get_dumped_info[ns].type} #{ns.ary[-1]}\n" )
        result.push( "end\n" )
        ns = ns.chop
      end

      result
    end
    
    def extract_superclass( namespace, new_class, targets, path, lineno )
      @files.each do |scriptfile|
        scriptfile.extract_superclass( namespace, new_class, targets )
      end
      
      deffile = @files.find{|scriptfile| scriptfile.path == path}
      new_superclass = get_dumped_info[targets.first].superclass.class_name
      def_str = superclass_def( namespace, new_class,
                                new_superclass,
                                deffile.class_on(lineno) )
      deffile.add_superclass_def( def_str, lineno )
    end
    
    def extract_superclass?( namespace, new_class, targets, path, lineno )
      # check namespace exists?
      if namespace != RRB::Namespace::Toplevel &&
         get_dumped_info[namespace].invalid?
        @error_message = "#{namespace.name}: No such namespace"
        return false
      end
      # check all targets exist?
      targets.each do |klass|
        @error_message = "#{klass.name}: No such class"
        return false unless get_dumped_info[klass].type == "class"
      end
      
      # check targets have the same superclass
      superclass = get_dumped_info[targets.first].superclass
      targets.each do |klass|
        @error_message = "#{targets.first.name} and #{klass.name} are not sibling classes"
        return false unless get_dumped_info[klass].superclass == superclass
      end

      # check name collision
      unless get_dumped_info.resolve_const( namespace, new_class ).nil? then
        @error_message = "#{new_class}: already exists"
        return false
      end

      # check where new class is defined
      if class_on( path, lineno ).nil? ||
         ! class_on( path, lineno ).contain?( namespace )
        @error_message = "Invalid Position to define new class"
        return false
      end
      
      return true
    end
    
  end
end
