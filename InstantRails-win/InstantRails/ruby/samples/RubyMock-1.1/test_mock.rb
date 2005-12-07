# Ruby/Mock version 1.0
# 
# Unit tests for the Mock class.
# Copyright (c) 2001 Nat Pryce, all rights reserved
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

require 'runit/testcase'
require 'mock'


class TestMock < RUNIT::TestCase
    class MockClass < Mock
        def test_precondition( arg )
            arg != nil
        end
        
        def test_precondition_with_block
            block_given?
        end
    end
    
    def setup
        @mock = Mock.new("TestedMock")
    end
    
    def teardown
        @mock = nil
    end
    
    def test_invalid_method_throws_assertion_failed
        assert_exception(RUNIT::AssertionFailedError) { @mock.invalid_method }
    end
    
    def test_successful_call_with_fixed_number_of_args
        @mock.__next(:no_args) { "success" }
        @mock.__next(:one_arg) { |a| "#{a}" }
        @mock.__next(:two_args) { |a,b| "#{a},#{b}" }
        
        assert_equals( "success", @mock.no_args )
        assert_equals( "success2", @mock.one_arg("success2") )
        assert_equals( "1,2", @mock.two_args(1,2) )
    end
    
    def test_too_few_args_with_fixed_number_of_args
        @mock.__next(:one_arg) { |a,| nil }
        @mock.__next(:two_args) { |a,b,| nil }
        
        assert_exception(RUNIT::AssertionFailedError) { @mock.one_arg }
        assert_exception(RUNIT::AssertionFailedError) { @mock.two_args(1) }
    end
    
    def test_too_many_args_with_fixed_number_of_args
        @mock.__next(:no_args) { || nil }
        @mock.__next(:two_args) { |a,b,| nil }
        
        assert_exception(RUNIT::AssertionFailedError) { @mock.no_args(1) }
        assert_exception(RUNIT::AssertionFailedError) { @mock.two_args(1,2,3) }
    end
    
    def test_block_called_when_passed_with_fixed_number_of_args
        @mock.__next(:no_args) { |block,| block.call }
        @mock.__next(:two_args) { |block,a,b,|
            assert_equal( 1, a )
            assert_equal( 2, b )
            block.call
        }
        
        block_called = false
        @mock.no_args { block_called = true }
        assert( block_called )
        
        block_called = false
        @mock.two_args(1,2) { block_called = true }
        assert( block_called )
    end
    
    def test_successful_call_with_variable_number_of_args
        @mock.__next(:varargs) { |*a| a }
        @mock.__next(:varargs) { |*a| a }
        @mock.__next(:varargs) { |*a| a }
        @mock.__next(:varargs) { |a,*b| [a,b] }
        @mock.__next(:varargs) { |a,*b| [a,b] }
        
        assert_equals( [],        @mock.varargs() )
        assert_equals( [1],       @mock.varargs(1) )
        assert_equals( [1,2],     @mock.varargs(1,2) )
        assert_equals( [1,[]],    @mock.varargs(1) ) 
        assert_equals( [1,[2,3]], @mock.varargs(1,2,3) ) 
    end
    
    def test_too_few_args_with_variable_number_of_args
        @mock.__next(:varargs) { |a,*b| [a,b] }
        @mock.__next(:varargs) { |a,b,*b| [a,b] }
        
        assert_exception(RUNIT::AssertionFailedError) { @mock.varargs }
        assert_exception(RUNIT::AssertionFailedError) { @mock.varargs(1) }
    end
    
    def test_block_called_when_passed_with_variable_number_of_args
        @mock.__next(:varargs) { |block,*args| 
            assert_equal( [], args )
            block.call 
        }
        @mock.__next(:varargs) { |block,*args|
            block.call 
            assert_equal( [1,2], args )
        }
        
        block_called = false
        @mock.varargs { block_called = true }
        assert( block_called )
        
        block_called = false
        @mock.varargs(1,2) { block_called = true }
        assert( block_called )
    end
    
    def test_too_many_calls_causes_failure
        @mock.__next(:no_args) {nil}
        @mock.__next(:no_args) {nil}
        
        assert_no_exception { @mock.no_args }
        assert_no_exception { @mock.no_args }
        assert_exception(RUNIT::AssertionFailedError) { @mock.no_args }
    end
    
    def test_no_error_when_all_methods_called
        @mock.__next(:f) {nil}
        @mock.__next(:f) {nil}
        
        @mock.f
        @mock.f
        
        assert_no_exception { @mock.__verify }
    end
    
    def test_error_when_not_all_methods_are_called
        @mock.__next(:f) {nil}
        @mock.__next(:f) {nil}
        
        @mock.f
        assert_exception(RUNIT::AssertionFailedError) do
            @mock.__verify
        end
    end
    
    def test_precondition_pass
        m = MockClass.new
        m.__next(:test_precondition) { |arg,| m }
        
        assert_same( m, m.test_precondition( "good" ) )
        m.__verify
    end
    
    def test_precondition_fail
        m = MockClass.new
        m.__next(:test_precondition) { |arg,| m }
        
        assert_exception(RUNIT::AssertionFailedError) do
            m.test_precondition( nil )
        end
        m.__verify
    end

    def test_default_block_for_precondition
        m = MockClass.new
        m.__next(:test_precondition)

        assert_same( m, m.test_precondition( "good" ) )
        m.__verify
    end
    
    def test_block_passed_to_preconditoon
        m = MockClass.new
        m.__next(:test_precondition_with_block) { |block,| block.call }
        m.__next(:test_precondition_with_block) { |block,| block.call }
        
        block_called = false
        m.test_precondition_with_block { block_called = true }
        assert( block_called )
        
        assert_exception(RUNIT::AssertionFailedError) do
            m.test_precondition_with_block
        end
    end
    
    def test_no_default_block_without_precondition
        assert_exception(RuntimeError) do
            @mock.__next(:no_precondition)
        end
    end
end

if __FILE__ == $0
    require 'runit/cui/testrunner'
    require 'runit/testsuite'

    RUNIT::CUI::TestRunner.run( TestMock.suite )
end
