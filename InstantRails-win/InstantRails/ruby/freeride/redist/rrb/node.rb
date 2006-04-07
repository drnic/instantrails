require 'forwardable'

module RRB

  class Visitor

    def initialize
      @error_message = ""
    end

    def visit_class( namespace, class_node )
    end

    def visit_method( namespace, method_node )
    end

    def visit_toplevel( namespace, top_node )
    end

    def visit_node( namespace, node )
    end

    def visit_singleton_method( namespace, node )
    end

    def visit_class_method( namespace, node )
    end

    def visit_singleton_class( namespace, node )
    end

    attr_reader :error_message
  end

  
  class Node    
    
    def initialize( name_id, scope, head_kw, tail_kw )
      @name_id = name_id
      @class_defs = scope.class_defs
      @method_defs = scope.method_defs
      @local_vars = scope.local_vars
      @global_vars = scope.global_vars
      @instance_vars = scope.instance_vars
      @class_vars = scope.class_vars
      @consts = scope.consts
      @method_calls = scope.method_calls
      @fcalls = scope.fcalls
      @singleton_method_defs = scope.singleton_method_defs
      @class_method_defs = scope.class_method_defs
      @singleton_class_defs = scope.singleton_class_defs
      @assigned = scope.assigned
      @attr_readers = scope.attr_readers
      @attr_writers = scope.attr_writers
      @attr_accessors = scope.attr_accessors
      @range = SyntaxRange.new( head_kw, tail_kw )
    end

    attr_reader :name_id, :class_defs, :method_defs, :method_calls, :local_vars
    attr_reader :global_vars, :instance_vars, :class_vars, :consts
    attr_reader :fcalls, :singleton_method_defs, :class_method_defs
    attr_reader :singleton_class_defs
    attr_reader :assigned
    attr_reader :attr_readers, :attr_writers, :attr_accessors
    attr_reader :range
    
    def calls
      @fcalls + @method_calls
    end

    def head_keyword
      @range.head
    end

    def tail_keyword
      @range.tail
    end
    
    def method_info( method_name )
      @method_defs.find{|m| m.name == method_name}
    end

    def class_info( class_name )
      @class_defs.find{|c| c.name == class_name }
    end

    def classmethod_info(method_name)
      @class_method_defs.find{|c| c.name == method_name}
    end
    
    def name
      @name_id.name
    end

    def accept( visitor, namespace )
      visitor.visit_node( namespace, self )
    end
    
    def accept_children( visitor, namespace )
      @class_defs.each{|i| i.accept( visitor, namespace ) }
      @method_defs.each{|i| i.accept( visitor, namespace ) }
      @singleton_method_defs.each{|i| i.accept( visitor, namespace ) }
      @class_method_defs.each{|i| i.accept( visitor, namespace ) }
      @singleton_class_defs.each{|i| i.accept( visitor, namespace ) }
    end
    
  end

  # represent one script file    
  class TopLevelNode < Node

    def initialize( scope )
      super IdInfo.new( :toplevel, nil, nil, 'toplevel' ), scope, nil, nil
    end
    
    def accept( visitor )
      visitor.visit_toplevel( Namespace::Toplevel, self )
      super visitor, Namespace::Toplevel
      accept_children( visitor, Namespace::Toplevel )
    end
    
  end

  # represent one module
  class ModuleNode < Node
    
    def accept( visitor, namespace )
      visitor.visit_class( namespace, self )
      super
      accept_children( visitor, namespace.nested( self.name ) )
    end

  end

  # represent one class 
  class ClassNode < ModuleNode

    def initialize( name_id, scope, superclass, head_kw, tail_kw )
      super name_id, scope, head_kw, tail_kw
      @superclass = superclass      
    end

    attr_reader :superclass
  end
  
  # represent one method
  class MethodNode < Node
    def initialize( name_id, scope, args, head_kw, tail_kw )
      @args = args
      super name_id, scope, head_kw, tail_kw
    end

    def accept( visitor, namespace )
      visitor.visit_method( namespace, self )
      super
      accept_children( visitor, namespace )
    end

    def instance_method?
      true
    end

    def class_method?
      false
    end

    def method_factory
      Method
    end
    
    attr_reader :args
    
  end

  class SingletonMethodNode < Node

    def initialize( s_obj, method_name, scope, args, head_kw, tail_kw )
      @s_obj = s_obj
      @args = args
      super method_name, scope, head_kw, tail_kw
    end
    
    def accept( visitor, namespace )
      visitor.visit_singleton_method( namespace, self )
      super
      accept_children( visitor, namespace )
    end

    attr_reader :s_obj
    attr_reader :args
  end

  class ClassMethodNode < Node

    def initialize( sdef )
      super sdef.name_id, sdef, sdef.head_keyword, sdef.tail_keyword
    end

    def accept( visitor, namespace )
      visitor.visit_class_method( namespace, self )
      super
      accept_children( visitor, namespace )
    end

    def instance_method?
      false
    end

    def class_method?
      true
    end

    def method_factory
      ClassMethod
    end
  end

  class SingletonClassNode < Node

    def accept( visitor, namespace )
      visitor.visit_singleton_class( namespace, self )
      super
      accept_children( visitor, namespace.nested( "[sclass]" ) )
    end
    
  end
  
  class IdInfo
    attr_reader :type, :lineno, :pointer, :name
    
    def initialize( type, lineno, pointer, name )
      @type = type
      @lineno = lineno
      @pointer = pointer
      @name = name
    end

    def adjust_id!( lineno, pointer )
      if @lineno > 1 then
	raise RRBError, "eval string mustn't have \"\\n\":#{self.inspect}"
      end
      @lineno = lineno
      @pointer += pointer
    end

    def head_pointer
      @pointer - @name.size
    end

    def self?
      @type == :keyword && @name == "self"
    end
  end

  class ConstInfo
    attr_reader :elements_id
    
    def initialize( toplevel, id, lconst=nil )
      if lconst == nil
	@elements_id = [ id ]
      else
	@elements_id = lconst.elements_id + [ id ]
      end
      @toplevel = toplevel      
    end
    
    def ConstInfo.new_toplevel( id )
      new( true, id )
    end
    
    def ConstInfo.new_colon2( id, lconst )
      new( lconst.toplevel?, id, lconst )
    end
    
    def ConstInfo.new_normal( id )
      new( false, id )
    end

    def basename
      @elements_id.map{|i| i.name}.join('::')
    end
    
    def name
      basename
    end

    def toplevel?
      @toplevel
    end

    def adjust_id!( lineno, pointer )
      @elements_id.last.adjust_id!( lineno, pointer )
    end

    def body
      @elements_id.last
    end

    def self?
      false
    end

  end

  class SyntaxRange

    def initialize( head_kw, tail_kw )
      @head = head_kw
      @tail = tail_kw
    end

    attr_reader :head, :tail

    def contain?( range )
      @head.lineno < range.begin && range.end < @tail.lineno 
    end

    def out_of?( range )
      range.last < @head.lineno || @tail.lineno < range.first
    end
  end
  

  class Namespace
    include Enumerable
    extend Forwardable
    
    @@cache = Hash.new

    class << self
      alias _new new
    end
    
    def Namespace.new( ns )
      if @@cache.has_key?( ns ) then
        @@cache[ns]
      else
        _new( ns )
      end
    end
  
    def initialize( ns )
      case ns
      when Array
	@namespace = ns
      when String
        @@cache[ns] = self
	@namespace = ns.split('::')
        @namespace.shift if @namespace[0] == ""
      else
	raise TypeError, 'must be string or array'
      end
      @namespace.freeze
    end

    def Namespace.[]( arg )
      new( arg )
    end
    
    def name
      @namespace.join('::')
    end

    def abs_name
      if self == Toplevel then
        ''
      else
        '::' + name
      end
    end
    
    def ary
      @namespace
    end

    def ==(other)
      return false unless other.kind_of?( Namespace )
      ary == other.ary
    end

    def eql?(other)
      self == other
    end

    def contain?( other )
      @namespace == other.ary[0,@namespace.size]
    end
    
    def hash
      ary.hash
    end

    def inspect
      "#<RRB::NS: #{name}>"
    end

    def chop
      return nil if @namespace.empty?
      Namespace.new( @namespace[0..-2] )
    end

    def <=>(other)
      self.ary <=> other.ary
    end

    def nested( bare_name )
      Namespace.new( @namespace + [ bare_name ] )
    end
    
    Toplevel = Namespace.new( [] )
    Object = Namespace.new( ["Object"] )
     
    # this methods exist for test_node
    def_delegators :@namespace, :last
  end

  # shortcut name
  NS = Namespace

  class Method
    def initialize( namespace, bare_name )
      @namespace = namespace
      @bare_name = bare_name
    end

    attr_reader :bare_name, :namespace

    def instance_method?
      true
    end

    def class_method?
      false
    end

    def ==(other)
      other.kind_of?( Method ) &&
        @bare_name == other.bare_name &&
        @namespace == other.namespace
    end

    def match_node?( namespace, method_node )
      method_node.instance_method? &&
        namespace == @namespace &&
        method_node.name == @bare_name 
    end
    
    def name
      @namespace.name + '#' + @bare_name
    end

    def inspect
      "#<#{self.class.to_s} #{self.name}>"
    end

    def eql?(other)
      self == other
    end

    def hash
      @namespace.hash ^ @bare_name.hash 
    end

    def ns_replaced( new_namespace )
      Method.new( new_namespace, @bare_name )
    end

    def bare_name_replaced( new_bare_name )
      Method.new( @namespace, new_bare_name )
    end

    def Method.[](str)
      case str
      when /\A([^#.]*)#([^#.]+)\Z/
        Method.new( Namespace.new( $1 ), $2 )
      when /\A([^#.]*).([^#.]+)\Z/
        ClassMethod.new( Namespace.new( $1 ), $2 )
      else
        raise Error, "#{str} is invalid as method name"
      end
    end

  end

  class ClassMethod
    def initialize( namespace, bare_name )
      @namespace = namespace
      @bare_name = bare_name
    end

    attr_reader :bare_name, :namespace
    
    def instance_method?
      false
    end

    def class_method?
      true
    end

    def ==(other)
      other.instance_of?( ClassMethod ) &&
        @bare_name == other.bare_name &&
        @namespace == other.namespace
    end

    def match_node?( namespace, method_node )
      method_node.class_method? &&
        namespace == @namespace &&
        method_node.name == @bare_name
    end
    
    def name
      @namespace.name + '.' + @bare_name
    end

    def eql?( other )
      self == other
    end

    def hash
      @namespace.hash ^ @bare_name.hash ^ 0xc9
    end
    
    def inspect
      "#<#{self.class.to_s} #{self.name}>"
    end

    def ns_replaced( new_namespace )
      ClassMethod.new( new_namespace, @bare_name )
    end

    def bare_name_replaced( new_bare_name )
      ClassMethod.new( @namespace, new_bare_name )
    end

  end
  
  # shortcut name
  MN = Method
  CMN = ClassMethod

  class NodeMethod

    def initialize( namespace, method_node )
      @namespace = namespace
      @node = method_node
    end

    attr_reader :namespace, :node
    
    def bare_name
      if @node
        @node.name
      else
        ""
      end
    end
    
    def local_vars
      Set.new( @node.local_vars.map{|var| var.name} )
    end

    def name
      if @namespace
        if @node.instance_method?
          @namespace.name + '#' + bare_name
        elsif @node.class_method?
          @namespace.name + '.' + bare_name
        end
      else
        bare_name
      end
    end

    def instance_method?
      @node.instance_method?
    end

    def class_method?
      @node.class_method?
    end

    def self.new_toplevel
      new( nil, nil )
    end

    def method_factory
      @node.method_factory
    end
  end
  
  class MethodCall
    extend Forwardable
    def initialize(body, args)
      @body = body
      @args = args
    end

    attr_reader :body, :args
    def_delegators :@body, :adjust_id!
    def name
      body.name
    end
  end

end
