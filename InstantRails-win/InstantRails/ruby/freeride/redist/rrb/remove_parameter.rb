require 'rrb/script'
require 'rrb/common_visitor'

require 'stringio'

module RRB

  class GetParameterIndexVisitor < Visitor
    def initialize(method_name, target_parameter)
      @method_name = method_name
      @target_parameter = target_parameter
      @parameter_index = nil
    end

    attr_reader :parameter_index

    def visit_method( namespace, node )
      return unless @method_name.instance_method?

      if @method_name.match_node?( namespace, node )
        @parameter_index = node.args.map{|arg| arg.name}.index(@target_parameter)
      end
    end
  end



  class RemoveParameterVisitor < Visitor

    def initialize(dumped_info, method_name, parameter_index)
      @dumped_info = dumped_info
      @method_name = method_name
      @parameter_index = parameter_index
      @result = []
    end

    attr_reader :result

    def remove_method_def_parameter(node)
      remove_arg = node.args[@parameter_index]
      @result << Replacer.new_from_id(remove_arg, '' )

    end

    def remove_fcall_parameter( fcall )
      remove_arg = fcall.args[@parameter_index]
      if remove_arg
        @result << Replacer.new_from_id(remove_arg, '')
      end
    end
    
    def visit_method( namespace, node )
      return unless @method_name.instance_method?

      if @method_name.match_node?( namespace, node )
        remove_method_def_parameter(node)
      end

      node.fcalls.each do|fcall|
        called = Method.new( namespace, fcall.name )
        real_called = @dumped_info.real_method( called )
        if real_called == @method_name
          remove_fcall_parameter(fcall)
        end
      end
    end
  end

  class RemoveParameterCheckVisitor < Visitor

    def initialize( method_name, target_parameter)
      @method_name = method_name
      @target_parameter = target_parameter
      @result = true
    end

    def visit_method(namespace, node)
      return unless @method_name.instance_method?

      if @method_name.match_node?( namespace, node )
        unless node.args.map{|arg| arg.name}.include?(@target_parameter)
          @error_message = "#{@target_parameter}: no such parameter"
          @result = false
        end
        
        if node.local_vars.map{|local_var| local_var.name}.find_all{|var_name|
            var_name == @target_parameter}.size >= 2
          @error_message = "#{@target_parameter} is used"
          @result = false
        end
      end
      
      if namespace == @namespace 
        node.fcalls.find_all{|fcall| fcall.name == @method_name.bare_name}.each do |fcall|
          if fcall.args.include?(nil) || fcall.args == []
            @error_message = "parameter is too complex"
            @result = false
          end
        end
      end
    end
    
    attr_reader :result
  end
  
  

  class ScriptFile
    def get_parameter_index( method_name, target_parameter)
      visitor = GetParameterIndexVisitor.new(method_name, target_parameter) 
      @tree.accept( visitor )
      return visitor.parameter_index
    end

    def remove_parameter(dumped_info, method_name, parameter_index)
      visitor = RemoveParameterVisitor.new(dumped_info,
                                           method_name,
                                           parameter_index) 
      @tree.accept( visitor )
      @new_script = RRB.replace_str( @input, visitor.result )
    end

    def remove_parameter?(method_name, target_parameter)
      visitor = RemoveParameterCheckVisitor.new(method_name,
                                                target_parameter)
      @tree.accept( visitor )
      @error_message = visitor.error_message unless visitor.result
      return visitor.result
    end
  end

  class Script    
    def get_parameter_index( method_name, target_parameter)
      @files.inject(nil) do |parameter_index, scriptfile|
        parameter_index ||= scriptfile.get_parameter_index(method_name,
                                                           target_parameter)
      end
    end

    def remove_parameter(method_name, target_parameter)
      parameter_index = get_parameter_index(method_name,
                                            target_parameter)
      @files.each do |scriptfile|
	scriptfile.remove_parameter(get_dumped_info, method_name, parameter_index)
      end
    end
    
    def remove_parameter?( method_name, target_parameter)

      unless get_dumped_info.exist?( method_name, false )
        @error_message = "#{method_name.name} isn't defined"
        return false
      end
      
      @files.each do |scriptfile|
        unless scriptfile.remove_parameter?(method_name,
                                            target_parameter)
          @error_message = scriptfile.error_message
          return false          
        end
      end
      
      return true
    end
  end
end
