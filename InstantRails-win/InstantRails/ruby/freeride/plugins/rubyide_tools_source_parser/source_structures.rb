# Purpose: 
#
# $Id: source_structures.rb,v 1.3 2005/12/08 11:29:19 jonathanm Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2003 Rich Kilmer. All rights reserved.
#
module FreeRIDE
  module Tools
    module SourceStructures
    
      class RubyGlobalContext
        def initialize
          @required = []
        end
      end
      
      class Source
        attr_reader :filename, :path, :top_level_context
        
        def initialize(filename, path, context)
          @filename = filename
          @path = path
          @top_level_context = context
        end
      end
      
      class CodeObject
        attr_accessor :parent
      end
      
      class Atom < CodeObject
        
        attr_reader :point, :name
        
        def initialize(point, name = nil)
          @point = point
        end
        
      end
      
      class Region < CodeObject
        
        attr_reader :start_point, :end_point, :num_lines
        attr_accessor :num_comments
        
        def initialize(s_p, e_p = nil)
          @start_point = s_p
          @end_point = e_p
          @num_lines = 0
          @num_comments = 0
        end
        
        def end_point=(e_p)
          @end_point = e_p
          @num_lines = e_p.line_no - @start_point.line_no
        end
        
      end
      
      class Context < Region
        
        #attr_reader :attr_list, :alias_list
        #attr_reader :require_list, :include_list
        attr_reader :method_list, :class_list, :module_list #, :block_list
        attr_reader :singleton_class_list, :singleton_method_list
        #attr_reader :instance_var_list, :class_var_list, :global_var_list, :local_var_list, :constant_list
        #alias_method :identifier_list, :local_var_list
  
        attr_reader :name#, :visibility            
        attr_accessor :parent
        attr_accessor :total_num_comments
        
        def initialize(s_p, name = nil)
          super(s_p)
          
          @name = name
          #@alias_list = []
          #@attr_list = []
          
          #@block_list = []
          @method_list = []
          @class_list = []
          @module_list = []
          
          @singleton_method_list = []
          @singleton_class_list = []
          
          #@constant_list = []
          #@local_var_list = []
          #@instance_var_list = []
          #@class_var_list = []
          #@global_var_list = []
          
          @parent = nil
          #@visibility = :public
          
          #@include_list = []
          #@require_list = []
        end
        
        #        def add_alias(new_alias)
        #  	@alias_list.push(new_alias)
        #  	new_alias.parent = self
        #        end
        
        #        def add_attribute(new_attr)
        #  	@attr_list.push(new_attr)
        #  	new_attr.parent = self
        #  	new_attr.visibility = @visibility
        #        end
        
        #        def add_require(req)
        #  	@require_list.push(req)
        #  	req.parent = self
        #        end
        
        #        def add_include(inc)
        #  	@include_list.push(inc)
        #  	inc.parent = self
        #        end
        
        #      def add_block(b)
        #	@block_list.push(b)
        #	b.parent = self
        #	b.visibility = @visibility
        #      end
        
        def add_method(m)
          @method_list.push(m)
          m.parent = self
          
          #m.qualified_name
          m.visibility = @visibility
        end
        
        def add_class(c)
          @class_list.push(c)
          c.parent = self
        end
        
        def add_module(mod)
          @module_list.push(mod)
          mod.parent = self
        end
        
        def add_singleton_method(m)
          @singleton_method_list.push(m)
          m.visibility = @visibility
          m.parent = self
        end
        
        def add_singleton_class(c)
          @singleton_class_list.push(c)
          c.parent = self
        end
        
        #        def add_constant(const)
        #  	@constant_list.push(const)
        #  	const.parent = self
        #        end
        
        #        def add_global_var(gv)
        #  	@global_var_list.push(gv)
        #  	gv.parent = self
        #        end
        
        #        def add_instance_var(iv)
        #  	@instance_var_list.push(iv)
        #  	iv.parent = self
        #        end
        
        #        def add_class_var(cv)
        #  	@class_var_list.push(cv)
        #  	cv.parent = self
        #        end
        
        #        def add_local_var(lv)
        #  	@local_var_list.push(lv)
        #  	lv.parent = self
        #        end
        
        #        def set_visibility_for(methods, vis)
        #  	@method_list.each_with_index do |m,i|
        #  	  if methods.include?(m.name)
        #  	    m.visibility = vis
        #  	  end
        #  	end
        #        end
        
        #        def ongoing_visibility=(vis)
        #  	@visibility = vis
        #        end
        
        def each_module
          @module_list.each { |mod| yield mod }
        end
        
        def each_class
          @class_list.each { |klass| yield klass }
        end
        
        def each_method
          @method_list.each { |m| yield m }
        end
        
        def each_singleton_method
          @singleton_method_list.each { |m| yield m }
        end
        
        def each_singleton_class
          @singleton_class_list.each { |c| yield c }
        end
        
        def qualified_name
          raise StandardError, 'Context#qualified_name must be implemented in subclass.'
        end
        
        # Calculate the total number of comments, including those of child elements
        def calculate_total_comments
          @total_num_comments = @num_comments
          (@module_list + @class_list + @method_list + @singleton_method_list + 
                @singleton_class_list).each do |ctx|
            ctx.calculate_total_comments
            @total_num_comments += ctx.total_num_comments
          end
        end
        
      end
      
      class AnyModule < Context
  
        def qualified_name
          res = @parent.qualified_name
          if res == ''
            res = @name
          else
            res += '::' + @name
          end
          
          res 
        end
        
      end
      
      # TopLevel is in the context of Object's object
      class TopLevelContext < AnyModule
        attr_accessor :num_whitespace
        
        def initialize
          super( Position.new(0,0) )
          @name = ''
        end
        
        def qualified_name
          ''
        end
      end
      
      class NormalModule < AnyModule
      end
      
      class NormalClass < AnyModule
        attr_accessor :super_class
      end
      
      class SingletonClass < AnyModule
        # in some cases, this doesn't return the accurate name.
        def qualified_name
          @parent.qualified_name
        end
        
      end
      
      class AnyMethod < Context
        attr_accessor :visibility#, :params, :block_params
      end
      
      class SingletonMethod < AnyMethod
        
        SEPARATOR = '.'
        
        attr_reader :obj_name, :method_name
        
        def initialize(point, name)
          super(point, name)
          @obj_name, @method_name = name.split(SEPARATOR, 2)
        end
        
        def qualified_name
          res = @parent.qualified_name.dup << '.' << @method_name
          res
          #@method_name
        end
      end
      
      class NormalMethod < AnyMethod
        def qualified_name
          res = @parent.qualified_name
          if res == ''
            res = @name
          else
            res += '#' + @name
          end
        end
      end
      
      class Identifier < Atom
      end
      
      class LocalVar < Identifier
      end
      
      class InstanceVar < Identifier
      end
      
      class ClassVar < Identifier
      end
      
      class GlobalVar < Identifier
      end
      
      class Include < Atom      
      end
      
      class Alias < Atom
        
        SEPARATOR = ','
        
        attr_reader :new_name, :old_name
        
        def initialize(name, lex_token, nest, scope)
          super(name, lex_token, nest, scope)
          @new_name, @old_name = name.split(SEPARATOR, 2)
        end
        
        #def set_alias(new_n, old_n)
        #  @old_name = old_n
        #  @new_name = new_n
        #end
        
        #def alias_name 
        #	@new_name + ':' + @old_name
        #end
        
      end
      
      class Attr < Atom
        
        R = :read
        W = :write
        RW = :readwrite
        
        attr_accessor :mode, :visibility
        
      end
      
      class Require < Atom
      end
      
      class MethodParameters < CodeObject
        
        attr_reader :args, :multiple_arg, :block_arg
        
        def initialize(args)
          block_arg = ''
          multiple_arg = ''
          if /^\&/ =~ args[-1]
            block_arg = args.pop
          end
          if /^\*/ =~ args[-1]
            multiple_arg = args.pop
          end
          
          @multiple_arg = multiple_arg
          @block_arg = block_arg
          @args = args
        end
        
        def has_block_arg?
          if @block_arg != ''
            return true
          else
            return false
          end
        end
        
        def has_multiple_arg?
          if @multiple_arg != ''
            return true
          else
            return false
          end
        end
        
        def arity
          sign = @multiple_arg ? -1 : 1
          num has_block_arg? ? 1 : 0
          num += @args.size
          
          num *= sign
          num
        end
        
        def name
          result = args.join(', ') 
          if @multiple_arg 
            result << ', *' + @multiple_arg 
          end
          if @block_arg 
            result << ', &' + @block_arg
          end
          
          result
        end
        
      end
      
      class BlockParameters < CodeObject
        attr_reader :args
        
        def initialize(args)
          @args
        end
        
        def arity
          @args.size
        end
      end
      
    end
  end
end

