
module RRB
  DEFINE_LOAD_SCRIPT = <<'EOS'
$__rrb_load_path = Array.new
$__rrb_loaded = Array.new
alias __rrb_orig_require require
def __rrb_search( file )
  $__rrb_load_path.each do |path|
    fname = File.join( path, file )
    return fname if File.file?( fname )
    fname = File.join( path, file + ".rb" )
    return fname if File.file?( fname )
  end
  return nil
end
def __rrb_load( file )

  fname = __rrb_search( file )
  if fname == nil
    return __rrb_orig_require( file )
  end
  unless $__rrb_loaded.member?( fname ) 
    load fname
    $__rrb_loaded << fname
    return true
  end

  return false
end
def require( feature )
  __rrb_load( feature )
end

EOS
  
  DUMP_MODULES_SCRIPT = <<'EOS'
ObjectSpace.each_object( Module ) do |mod|

  # 0 class type
  case mod
  when Class
    print "class"
  when Module
    print "module"
  else
    print "unknown"
  end
  
  print "#"

  # 1 class hierarchy( first of this is name of this class )
  mod.ancestors.each do |ancestor|
    print ancestor.name, ";"
  end

  print "#"

  # 2 public instance methods
  mod.public_instance_methods(false).each do |method_name|
    print method_name, ";"
  end

  print "#"

  # 3 protected instance methods
  mod.protected_instance_methods(false).each do |method_name|
    print method_name, ";"
  end

  print "#"

  # 4 private instance methods
  mod.private_instance_methods(false).each do |method_name|
    print method_name, ";"
  end

  print "#"

  # 5 singleton_methods
  if RUBY_VERSION >= '1.8.0' then
    mod.singleton_methods(false).each do |method_name|
      print method_name, ";"
    end
  else
    class << mod
      public_instance_methods(false).each do |method_name|
        print method_name, ";"
      end
    end
  end

  print '#'
  
  # 6 constants
  mod.constants_not_inherited_too.each do |const_name|
    print const_name, ";"
  end
  
  print "\n"

end

EOS

end
