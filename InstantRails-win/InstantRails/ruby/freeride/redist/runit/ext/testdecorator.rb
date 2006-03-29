module RUNIT
  module EXT
    module TestDecorator
      def initialize(test)
        @test = test
        decorated(self)
      end
      def count_test_cases
        @test.count_test_cases
      end
      def run(result)
        @test.run(result)
      end
      def decorated(decorator)
        @test.decorated(decorator) if @test.respond_to?(:decorated)
      end
      def extend_test(*mod)
        @test.extend_test(*mod)
      end
    end
  end

  class TestSuite
    def decorated(decorator)
      each do |t|
        t.decorated(decorator) if t.respond_to?(:decorated)
      end
    end
  end
end

