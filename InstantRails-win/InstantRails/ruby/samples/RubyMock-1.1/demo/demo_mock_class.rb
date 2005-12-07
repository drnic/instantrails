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


# Derive from Mock to define preconditions for a set of methods.  The
# method definitions should return a boolean value.  The preconditions
# are checked before any assertions defined by blocks passed to the
# __next method.
#
class StoragePreconditions < Mock
    def open
        true
    end
    
    def write( string )
        string != nil && string != ""
    end
    
    def close
        true
    end
end


# These tests use the StoragePreconditions class to create mock objects, so
# that they inherit the generic preconditions of the storage interface.
# 
class TestFileReader < RUNIT::TestCase
    def test_successful_write
        file = StoragePreconditions.new
        file.__next(:open) { || file }
        file.__next(:putline) { |str,| assert_equal("hello, world!",str) }
        file.__next(:close) { || file }
        
        h = HelloWriter.new
        
        h.hello( file )
        file.__verify
    end
    
    def test_different_name
        file = StoragePreconditions.new
        file.__next(:open) { || file }
        file.__next(:putline) { |str,| assert_equal("hello, gorgeous!",str) }
        file.__next(:close) { || file }
        
        h = HelloWriter.new("gorgeous")
        
        h.hello( file )
        file.__verify
    end
    
    def test_no_write_on_open_error
        file = StoragePreconditions.new
        file.__next(:open) { || raise "i/o error" }
        
        h = HelloWriter.new
        
        assert_exception(RuntimeError) { h.hello( file ) }
        file.__verify
    end
    
    def test_close_on_write_error
        file = StoragePreconditions.new
        file.__next(:open) { || file }
        file.__next(:putline) { |str,| raise "i/o error" }
        file.__next(:close) { || file }
        
        h = HelloWriter.new
        
        assert_exception(RuntimeError) { h.hello( file ) }
        file.__verify
    end
end

RUNIT::CUI::TestRunner.run( TestFileReader.suite )
