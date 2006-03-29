require 'singleton'

module RRB
  
  class DumpedInfo

    include Enumerable
    def initialize( hash )
      @classes = hash
    end

    def [](index)
      index = Namespace.new( index ) if index.kind_of?( String )
      raise unless index.kind_of?( Namespace )
      @classes[index]
    end

    def each( &block )
      @classes.each_value( &block )
    end

    def classes_having_method( method )
      result = []
      @classes.each_value do |info|
	if info.has_method?( method, false ) then
	  result << info
	end
      end

      result
    end

    def resolve_const( namespace, const )
      
      if namespace == Namespace::Toplevel then
        if self["Object"].consts.include?( const ) then
          return Namespace::Toplevel
        else
          return nil
        end
      end
      
      ns = namespace
      until ns == Namespace::Toplevel
        return ns if self[ns].consts.include?( const )
        ns = ns.chop
      end

      classinfo = self[namespace].ancestors.find do |anc|
        anc.consts.include?( const )
      end
      
      return nil if classinfo == nil
      return Namespace::Toplevel if classinfo.class_name == Namespace::Object
      return classinfo.class_name
    end

    def exist?( methodname, inherited_too=true )
      if methodname.instance_method?
        self[methodname.namespace].has_method?( methodname.bare_name,
                                                inherited_too )
      else
        self[methodname.namespace].has_class_method?( methodname.bare_name,
                                                      inherited_too )
      end
    end

    def real_method( methodname )
      if methodname.instance_method?
        self[methodname.namespace].real_method( methodname.bare_name )
      else
        self[methodname.namespace].real_class_method( methodname.bare_name )
      end
    end

    def real_class_method( methodname )
      if methodname.instance_method?
        raise
      end
      self[methodname.namespace].real_class_method( methodname.bare_name )
    end
    
    def DumpedInfo.get_dumped_info( io )
      info_hash = Hash.new(NullDumpedClassInfo.instance)
      while line = io.gets
	split_list = line.chomp.split( /#/, -1 )
	info = DumpedClassInfo.new( split_list[0],
				   split_list[1].split(/;/),
				   split_list[2].split(/;/),
				   split_list[3].split(/;/),
				   split_list[4].split(/;/),
				   split_list[5].split(/;/),
				   split_list[6].split(/;/) )
	info_hash[info.class_name] = info
      end
      
      info_hash.each_value do |info|
	info.ancestors = info.ancestor_names.map{|name| info_hash[name]}
      end
      new(info_hash)
    end
  end
  
  class DumpedClassInfo
    
    
    def initialize( type, ancestor_names, public_method_names,
		   protected_method_names, private_method_names,
		   singleton_method_names, consts )
      @type = type
      @class_name = Namespace.new( ancestor_names[0] )
      @ancestor_names = ancestor_names[1..-1].map{|name| Namespace.new( name )}
      @public_method_names = public_method_names
      @protected_method_names = protected_method_names
      @private_method_names = private_method_names
      @singleton_method_names = singleton_method_names
      @consts = consts
    end
    
    attr_reader( :type, :class_name, :ancestor_names, :public_method_names,
		:protected_method_names, :private_method_names,
		:singleton_method_names, :consts )

    attr_accessor :ancestors
    
    def has_method?( methodname, inherited_too=true )
      if inherited_too then
	return true if has_method?( methodname, false )
	@ancestors.each do |ancestor|
	  return true if ancestor.has_method?( methodname, false )
	end
	return false
      end
      
      return true if @public_method_names.include?( methodname )
      return true if @protected_method_names.include?( methodname )
      return true if @private_method_names.include?( methodname )
      return false
    end

    def real_method( methodname )
      if has_method?( methodname, false )
        return Method.new( self.class_name, methodname )
      end
      @ancestors.each do |ancestor|
        if ancestor.has_method?( methodname, false )
          return Method.new( ancestor.class_name, methodname )
        end
      end
      nil
    end
    
    def has_class_method?( methodname, inherited_too=true )
      if inherited_too
        return true if has_class_method?( methodname, false )
        @ancestors.each do |ancestor|
	  return true if ancestor.has_class_method?( methodname, false )
	end
	return false
      end

      return @singleton_method_names.include?( methodname )
    end

    def real_class_method( methodname )
      if has_class_method?( methodname, false )
        return ClassMethod.new( self.class_name, methodname )
      end
      @ancestors.each do |ancestor|
        if ancestor.has_class_method?( methodname, false )
          return ClassMethod.new( ancestor.class_name, methodname )
        end
      end
      nil
    end
    
    def subclass_of?(classname)
      classname = Namespace.new( classname ) if classname.kind_of?( String )
      @ancestor_names.include?(classname) ||  @class_name == classname
    end

    def superclass
      ancestors.find{|anc| anc.type == "class"}
    end

    def invalid?
      false
    end
  end

  class NullDumpedClassInfo
    include Singleton
    def type; "NullDumpedClass" end
    def class_name; "NullDumpedClass" end
    def ancestor_names; [] end
    def protected_method_names; [] end
    def private_method_names; [] end
    def singleton_method_names; [] end
    def consts; [] end
    def ancestors; [] end
    
    def has_method?( methodname, inherited_too=true )
      false
    end
    def subclass_of?(classname)
      false
    end

    def ==(other)
      other.class == self.class
    end

    def invalid?
      true
    end
  end
  
end
