module RUNIT
  module ToPublic
    def to_public(klass)
      k = Class.new(klass)
      methods = klass.protected_instance_methods(true)
      methods += klass.private_instance_methods(true)
      methods.each do |m|
	k.class_eval("public :#{m}")
      end
      k
    end
    module_function :to_public
  end
end
