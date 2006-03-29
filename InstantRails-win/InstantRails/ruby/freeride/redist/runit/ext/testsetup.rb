require 'runit/ext/testdecorator'
module RUNIT
  module EXT
    module TestSetup 
      include TestDecorator
  
      def initialize(test)
        super(test)
      end

      def run(result)
        setup
	begin
          super
	ensure
          teardown
	end
      end
  
      def setup
      end
      private :setup
  
      def teardown
      end
      private :teardown
    end
  end
end

