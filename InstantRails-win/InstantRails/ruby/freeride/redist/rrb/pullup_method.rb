require 'rrb/scriptfile'
require 'rrb/script'
require 'rrb/node.rb'
require 'rrb/parser.rb'
require 'rrb/common_visitor'

module RRB

  class PullupMethodCheckVisitor < Visitor
    def initialize(dumped_info, method_name, new_namespace)
      @dumped_info = dumped_info
      @method_name = method_name
      @new_namespace = new_namespace
      @result = true
    end

    attr_reader :result

    def called_method(node, fcall)
      @dumped_info.real_method(node.method_factory.new(@method_name.namespace,
                                                       fcall.name))
    end
      
    def check_pullup_method(namespace, node)
      return unless @method_name.match_node?( namespace, node )
      
      node.fcalls.each do |fcall|
        called_method = called_method(node, fcall)
        unless @dumped_info[@new_namespace].subclass_of?( called_method.namespace )
          @result = false
          @error_message = "#{@method_name.name} uses #{called_method.name}"
        end
      end
    end

    def visit_method(namespace, node)
      return unless @method_name.instance_method?
      check_pullup_method(namespace, node)
    end

    def visit_class_method(namespace, node)
      return unless @method_name.class_method?
      check_pullup_method(namespace, node)
    end
  end

  class ScriptFile

    def pullup_method(method_name, new_namespace, pullupped_method, lineno)
      if method_name.class_method?
        pullupped_method.gsub!(/^((\s)*def\s+)(.*)\./) {|s| $1 + new_namespace.name + '.'}
      end

      visitor = MoveMethodVisitor.new( method_name, lineno )
      @tree.accept( visitor )
      pullupped_method = RRB.reindent_str_node( pullupped_method, visitor.inserted )
      @new_script = RRB.insert_str(@input, lineno,
                                   visitor.delete_range, pullupped_method )
    end

    def pullup_method?(dumped_info, method_name, new_namespace)
      visitor = PullupMethodCheckVisitor.new(dumped_info,
                                             method_name, new_namespace)
      @tree.accept(visitor)
      @error_message = visitor.error_message unless visitor.result
      return visitor.result
    end
  end

  class Script
    def pullup_method(method_name, new_namespace,
                      path, lineno)
      pullupped_method = get_string_of_method(method_name)
      @files.each do |scriptfile|
	scriptfile.pullup_method(method_name,
                                 new_namespace, pullupped_method,
                                 (scriptfile.path == path)? lineno : nil )
      end      
    end

    def pullup_method?(method_name, new_namespace,
                       path, lineno)
      old_namespace = method_name.namespace
      unless get_dumped_info.exist?( method_name, false )
        @error_message = "#{method_name.name} is not defined"
        return false
      end

      unless get_dumped_info[old_namespace].subclass_of?(new_namespace)
        @error_message = "#{new_namespace.name} is not the superclass of #{old_namespace.name}"
        return false
      end

      superclass = get_dumped_info[old_namespace].superclass
      super_method = get_dumped_info.real_method(method_name.ns_replaced(superclass.class_name))
      if super_method != nil
        @error_message = "#{super_method.name} is already defined"
        return false
      end


      target_class = class_on( path, lineno )
      unless target_class && new_namespace == target_class
        @error_message = "Specify which definition to pull up method to"
        return false
      end

      @files.each do |scriptfile|
        unless scriptfile.pullup_method?(get_dumped_info, method_name, new_namespace)
          @error_message = scriptfile.error_message
          return false          
        end
      end

      return true
    end
  end
end
