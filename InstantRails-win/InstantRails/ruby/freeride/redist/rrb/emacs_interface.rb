require 'rrb/rrb'

module RRB

  class EmacsInterface

    USAGE = "\
Usage: rrb refactoring-type refactoring-parameter io-type

  refactoring-type
    * --rename-local-variable  Class#method old_var new_var
    * --rename-method-all  old_method new_method
    * --rename-class-variable  Class old_var new_var
    * --rename-instance-variable  Class old_var new_var
    * --rename-global-variable  old_var new_var
    * --extract-method path new_method start_lineno end_lineno
    * --rename-method \"old-class1 old-class2...\" old_method new_method
    * --rename-constant old_const new_const
    * --pullup-method old_class#method new_class path lineno
    * --pushdown-method old_class#method new_class path lineno
    * --remove-parameter class#method parameter
    * --extract-superclass namespace new_class \"target-class1 target-class2...\" path lineno

  io-type
    * --stdin-stdout
    * --filein-overwrite FILES..
    * --filein-stdout FILES..
    * --marshalin-overwrite FILE
    * --marshalin-stdout FILE
"
    
    def initialize( argv )
      parse_argv argv
    end

    def parse_argv_rename_local_variable(argv)
      method_name = Method[argv.shift]
      old_var = argv.shift
      new_var = argv.shift
      @args = [ method_name, old_var, new_var ]
      @refactoring_method = :rename_local_var
      @check_method = :rename_local_var?
    end
    
    def parse_argv_rename_instance_variable(argv)
      namespace = Namespace.new( argv.shift )
      old_var = argv.shift
      new_var = argv.shift
      @args = [ namespace, old_var, new_var ]
      @refactoring_method = :rename_instance_var
      @check_method = :rename_instance_var?
    end
    
    def parse_argv_rename_class_variable(argv)
      namespace = Namespace.new( argv.shift )
      old_var = argv.shift
      new_var = argv.shift
      @args = [ namespace, old_var, new_var ]
      @refactoring_method = :rename_class_var
      @check_method = :rename_class_var?
    end
    
    def parse_argv_rename_global_variable(argv)
      old_var = argv.shift
      new_var = argv.shift
      @args = [ old_var, new_var ]
      @refactoring_method = :rename_global_var
      @check_method = :rename_global_var?
    end
    
    def parse_argv_extract_method(argv)
      filepath = argv.shift
      new_method = argv.shift
      start_lineno = argv.shift.to_i
      end_lineno = argv.shift.to_i
      @args = [ filepath, new_method, start_lineno, end_lineno ]
      @refactoring_method = :extract_method
      @check_method = :extract_method?
    end

    def parse_argv_rename_method(argv)
      classes = argv.shift.split(' ').map{|ns| RRB::NS.new(ns)}
      str_old_method = argv.shift
      old_methods = classes.map{|klass| Method.new(klass, str_old_method)}
      new_method = argv.shift
      @args = [ old_methods, new_method ]
      @refactoring_method = :rename_method
      @check_method = :rename_method?
    end
    
    def parse_argv_rename_method_all(argv)
      old_method = argv.shift
      new_method = argv.shift
      @args = [ old_method, new_method ]
      @refactoring_method = :rename_method_all
      @check_method = :rename_method_all?
    end
    
    def parse_argv_move_method(argv)
      method_name = argv.shift
      old_namespace = Namespace.new( argv.shift )
      new_namespace = Namespace.new( argv.shift )
      @args = [ method_name, old_namespace, new_namespace ]
      @refactoring_method = :move_method
      @check_method = :move_method?	
    end
    
    def parse_argv_rename_constant(argv)
      old_const = argv.shift
      new_const = argv.shift
      @args = [old_const, new_const]
      @refactoring_method = :rename_constant
      @check_method = :rename_constant?
    end

    def parse_argv_pullup_method(argv)
      method_name = Method[argv.shift]
      new_namespace = Namespace.new(argv.shift)
      path = argv.shift
      lineno = argv.shift.to_i
      @args = [ method_name, new_namespace, path, lineno]
      @refactoring_method = :pullup_method
      @check_method = :pullup_method?
    end

    def parse_argv_pushdown_method(argv)
      method_name = Method[argv.shift]
      new_namespace = Namespace.new(argv.shift)
      path = argv.shift
      lineno = argv.shift.to_i
      @args = [ method_name, new_namespace, path, lineno]
      @refactoring_method = :pushdown_method
      @check_method = :pushdown_method?
    end

    def parse_argv_remove_parameter(argv)
      namespace, method_name = split_method_name argv.shift
      target_parameter = argv.shift
      @args = [namespace, method_name, target_parameter]
      @refactoring_method = :remove_parameter
      @check_method = :remove_parameter?
    end

    def parse_argv_extract_superclass(argv)
      namespace = RRB::NS.new(argv.shift)
      new_class = argv.shift
      targets = argv.shift.split(' ').map{|ns| RRB::NS.new(ns)}
      path = argv.shift
      lineno = argv.shift.to_i
      @args = [namespace, new_class, targets, path, lineno]
      @refactoring_method = :extract_superclass
      @check_method = :extract_superclass?
    end
    
    def parse_argv( argv )

      # analyze REFACTORING-TYPE
      case argv.shift
      when '--rename-local-variable'
	parse_argv_rename_local_variable(argv)
      when '--rename-instance-variable'
	parse_argv_rename_instance_variable(argv)
      when '--rename-class-variable'
        parse_argv_rename_class_variable(argv)
      when '--rename-global-variable'
        parse_argv_rename_global_variable(argv)
      when '--rename-method-all'
        parse_argv_rename_method_all(argv)
      when '--extract-method'
        parse_argv_extract_method(argv)
      when '--move-method'
        parse_argv_move_method(argv)
      when '--rename-method'
        parse_argv_rename_method(argv)
      when '--rename-constant'
        parse_argv_rename_constant(argv)
      when '--pullup-method'
        parse_argv_pullup_method(argv)
      when '--pushdown-method'
        parse_argv_pushdown_method(argv)
      when '--remove-parameter'
        parse_argv_remove_parameter(argv)
      when '--extract-superclass'
        parse_argv_extract_superclass(argv)
      else
	raise RRBError, "Unknown refactoring"
      end

      # analyze IO-TYPE
      case argv.shift
      when '--stdin-stdout', nil
	@script = Script.new_from_io( STDIN )
	@output = proc{ @script.result_to_io( STDOUT ) }
      when '--filein-overwrite'      
	@script = Script.new_from_filenames( *argv )
	@output = proc{ @script.result_rewrite_file }
      when '--filein-stdout'
	@script = Script.new_from_filenames( *argv )
	@output = proc{ @script.result_to_io( STDOUT ) }
      when '--marshalin-overwrite'
	@script = Script.new_from_marshal( argv.shift )
	@output = proc{ @script.result_rewrite_file }
      when '--marshalin-stdout'
	@script = Script.new_from_marshal( argv.shift )
	@output = proc{ @script.result_to_io( STDOUT ) }
      else
	raise RRBError, "Unknown input/output option"
      end
      
    end

    def enable_refactor?
      @script.__send__ @check_method, *@args
    end

    def refactor
      @script.__send__ @refactoring_method, *@args
    end

    def output
      @output.call
    end

    def get_last_error
      @script.error_message
    end
    
  end

  
end
