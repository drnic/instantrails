require 'runit/ext/testdecorator'

module RUNIT
  module EXT
    class RepeatedTest
      include TestDecorator
      def initialize(test, repeat)
        super(test)
        @repeat = repeat
      end
      def run(result)
        @repeat.times do 
           super(result)
        end
      end
      def count_test_cases
        super * @repeat
      end
    end
  end
end
