# Ruby/Mock version 1.0
# 
# A demo of the Mock class.
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
require 'runit/cui/testrunner'
require '../mock'


# The class under test.  It writes a greeting into persistent storage.
# To test it, we will need to mock the storage object.
#
class HelloWriter
    def initialize( who = "world" )
        @who = who
    end
    
    def hello( storage )
        storage.open
        begin
            storage.putline( "hello, #{@who}!" )
        ensure
            storage.close
        end
    end
end


# This test uses a generic Mock object to mock the behaviour of the storage
# objects.
#
class TestFileReader < RUNIT::TestCase
    def test_successful_write
        # Create a mock storage object
        file = Mock.new
        
        # Describe the valid sequence of method calls to the mock object in
        # this test.  The __next method takes the name of the next method
        # to be called and a block that defines the arity of the method,
        # checks preconditions, checks that the tested object is passing
        # expected values to the mock object and finally returns the value
        # that would be returned from the mocked object.
        # 
        file.__next(:open) { || file }
        file.__next(:putline) { |str,| 
            # Generic preconditions
            assert_not_nil( str )
            assert( str != "" )
            
            # Expected parameter value
            assert_equal( "hello, world!", str )
        }
        file.__next(:close) { || file }
        
        h = HelloWriter.new
        
        h.hello( file )
	
	# At the end of the test, call the mock's __verify method to test
	# that all expected calls have been made to the mock.
	#
        file.__verify
    end
    
    def test_different_name
        # Different tests have different sequences of expected methods and
        # assertions.
        # 
        file = Mock.new
        file.__next(:open) { || file }
        file.__next(:putline) { |str,| 
            assert_not_nil( str )
            assert( str != "" )
            assert_equal( "hello, gorgeous!", str ) 
        }
        file.__next(:close) { || file }
        
        h = HelloWriter.new("gorgeous")
        
        h.hello( file )
        file.__verify
    end
    
    def test_no_write_on_open_error
        # A mock object can be used to test how a class reacts to errors
        # raised by the objects it uses.
        # 
        file = Mock.new
        file.__next(:open) { || raise "i/o error" }
        
        h = HelloWriter.new
        
        assert_exception(RuntimeError) { h.hello( file ) }
        file.__verify
    end
    
    def test_close_on_write_error
        file = Mock.new
        file.__next(:open) { || file }
        file.__next(:putline) { |str,| 
            assert_not_nil( str )
            assert( str != "" )
            raise "i/o error"
        }
        file.__next(:close) { || file }
        
        h = HelloWriter.new
        
        assert_exception(RuntimeError) { h.hello( file ) }
        file.__verify
    end
end


RUNIT::CUI::TestRunner.run( TestFileReader.suite )
