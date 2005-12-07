class Hello
    attr_reader :msg
    def initialize
        @msg = "Hello, World"
    end
end

h = Hello.new
puts h.msg
print "Press RETURN"
$stdin.gets
