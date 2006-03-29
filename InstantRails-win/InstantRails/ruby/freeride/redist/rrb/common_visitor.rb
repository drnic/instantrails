require 'rrb/node'

module RRB

  class MoveMethodVisitor < Visitor

    def initialize( moved_method, lineno )
      @moved_method = moved_method
      @lineno = lineno
      @delete_range = nil
      @inserted = nil
    end

    attr_reader :delete_range, :inserted

    def visit_class( namespace, class_node )
      return if @lineno.nil?
      if class_node.range.contain?( @lineno..@lineno )
        @inserted = class_node
      end
    end
    
    def visit_method(namespace, method_node )
      return unless @moved_method.instance_method? 
      return unless @moved_method.match_node?( namespace, method_node )
      @delete_range = method_node.range
    end

    def visit_class_method( namespace, cmethod_node )
      return unless @moved_method.class_method?
      return unless @moved_method.match_node?( namespace, cmethod_node )
      @delete_range = cmethod_node.range
    end
  end
  
  class GetStringOfMethodVisitor < Visitor
    def initialize(method_name)
      @method_name = method_name
      @result_range = nil
    end

    attr_reader :result_range

    def get_string_of_method(namespace, node)
      if @method_name.match_node?( namespace, node )
        @result_range = node.range
      end
    end

    def visit_method(namespace, node)
      get_string_of_method(namespace, node)
    end

    def visit_class_method(namespace, node)
      get_string_of_method(namespace, node)
    end
  end

  class GetClassOnRegionVisitor < Visitor
    def initialize( range)
      @range = range
      @namespace = Namespace::Toplevel 
    end
    attr_reader :namespace

    def visit_class(namespace, node)
      if node.range.contain?( @range ) then
        @namespace = namespace.nested( node.name ) 
      else
        unless node.range.out_of?(@range) then
          @namespace = nil
        end
      end
    end
  end
  class GetMethodOnRegionVisitor < Visitor
    def initialize( range)
      @range = range
      @method = NodeMethod.new_toplevel
    end
    attr_reader :method

    def get_method_on_region(namespace, node)
      if node.range.contain?( @range ) then
        @method = NodeMethod.new(namespace, node)
      else
        unless node.range.out_of?( @range ) then
          @method = nil
        end
      end
    end

    def visit_method(namespace, node)
      get_method_on_region(namespace, node)
    end
    def visit_class_method(namespace, node)
      get_method_on_region(namespace, node)
    end

  end

  class GetNamespaceOnLineVisitor < Visitor
    def initialize( lineno )
      @lineno = lineno..lineno
      @namespace = Namespace::Toplevel
      @node = nil
    end

    attr_reader :namespace, :node
    
    def check_out_of( node )
      unless node.range.out_of?( @lineno )
        @namespace = @node = nil
      end
    end
    
    def visit_class( namespace, node )
      if node.range.contain?( @lineno )
        @namespace = namespace.nested( node.name )
        @node = node
      end
    end
    
    def visit_method( namespace, node )
      check_out_of( node )
    end

    def visit_class_method( namespace, node )
      check_out_of( node )
    end

    def visit_singleton_method( namespace, node )
      check_out_of( node )
    end
  end

  class ScriptFile
    def get_string_of_method(method_name)
      visitor = GetStringOfMethodVisitor.new(method_name)
      @tree.accept(visitor)
      range = visitor.result_range
      range && @input.split(/^/)[range.head.lineno-1..range.tail.lineno-1].join
    end

    def get_method_on_region(range)
      visitor = GetMethodOnRegionVisitor.new( range )
      @tree.accept( visitor )
      visitor.method
    end

    def get_class_on_region(range)
      visitor = GetClassOnRegionVisitor.new( range )
      @tree.accept( visitor )
      visitor.namespace
    end    
    
    def class_on( lineno )
      visitor = GetNamespaceOnLineVisitor.new( lineno )
      @tree.accept( visitor )
      visitor.namespace
    end

    def class_node_on( lineno )
      visitor = GetNamespaceOnLineVisitor.new( lineno )
      @tree.accept( visitor )
      visitor.node
    end

  end

  class Script
    def get_string_of_method(method_name)
      @files.inject(nil) do |result, scriptfile|
        result ||= scriptfile.get_string_of_method(method_name)
      end
    end
    
    def get_class_on_region(path, range)
      target_scriptfile = @files.find(){|scriptfile| scriptfile.path == path}
      target_scriptfile && target_scriptfile.get_class_on_region(range)
    end
    
    def get_method_on_region(path, range)
      target_scriptfile = @files.find(){|scriptfile| scriptfile.path == path}
      target_scriptfile && target_scriptfile.get_method_on_region(range)
    end

    def get_class_on_cursor(path, lineno)
      get_class_on_region(path, lineno..lineno)
    end

    def get_method_on_cursor(path, lineno)
      get_method_on_region(path, lineno..lineno)
    end

    def class_on( path, lineno )
      @files.find{|scriptfile| scriptfile.path == path}.class_on( lineno )
    end

  end
end
