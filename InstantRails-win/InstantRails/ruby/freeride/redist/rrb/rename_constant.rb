require 'rrb/script'
require 'pp'

module RRB

  module ConstResolver
    def resolve_const(dumped_info,ns,const)
      if const[0,2] == "::"
        return const[2..-1]
      end

      ans = dumped_info.resolve_const( Namespace.new(ns), const.split('::')[0] )
      if ans == nil then
        return nil
      else
        if ans == Namespace::Toplevel then
          return "#{const}"
        else
          return "#{ans.name}::#{const}"
        end
      end
    end

    def class_of(constname)
      if constname[0,2]=="::"
        ret = constname.split('::')[1..-2].join('::')
      else
        ret = constname.split('::')[0..-2].join('::')
      end
      
      if ret==""
        "Object"
      else
        ret
      end
    end
    
  end
  
  class RenameConstantVisitor < Visitor
    include ConstResolver
    
    def initialize(dumped_info, old_const, new_const_body)
      if old_const[0,2] != '::' then
        @old_const = old_const
      else
        @old_const = old_const[2..-1]
      end
      @old_const_body = old_const.split("::")[-1]
      @new_const_body = new_const_body
      @dumped_info = dumped_info
      @result = []
    end
    
    attr_reader :result
    
    def visit_node(namespace, node)
      ns = namespace.name
      #if node isn't method definition..
      if ModuleNode === node || SingletonClassNode === node
        ns << '::' unless namespace.name==""
        ns << node.name_id.name
      end
      
      node.consts.each do |constinfo|
        next if constinfo.body.name != @old_const_body
        
        if constinfo.toplevel?
          used_const = constinfo.name
        else
          used_const = resolve_const(@dumped_info, ns, constinfo.name)
        end
        
        if used_const == @old_const then
          id = constinfo.body
          @result << Replacer.new_from_id( id, @new_const_body)
        end
      end
    end

    def visit_class(namespace, node)
      if resolve_const(@dumped_info, namespace.name, node.name_id.name) == @old_const
        @result << Replacer.new_from_id( node.name_id, @new_const_body )
      end
    end

  end


  class ScriptFile

    def rename_constant(dumped_info, old_const, new_const)
      visitor = RenameConstantVisitor.new(dumped_info, old_const, new_const)
      @tree.accept(visitor)
      @new_script = RRB.replace_str(@input, visitor.result)
    end

  end

  class Script

    def rename_constant(old_const, new_const)
      @files.each do |scriptfile|
        scriptfile.rename_constant(get_dumped_info, old_const, new_const)
      end
    end

    def rename_constant?(old_const, new_const)
      unless RRB.valid_const?(new_const)
        @error_message = "#{new_const} is not a valid name for constants"
        return false
      end

      ns = Namespace.new(old_const)
      result_namespace = get_dumped_info.resolve_const( ns.chop, new_const )
      unless result_namespace.nil? then
        @error_message = "#{result_namespace.name}::#{new_const} is already defined"
        return false
      end

      return true
    end

  end

end
      
                        
