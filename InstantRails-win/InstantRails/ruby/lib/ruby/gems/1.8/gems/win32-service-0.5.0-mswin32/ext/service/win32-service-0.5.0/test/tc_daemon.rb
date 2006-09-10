#########################################################################
# tc_daemon.rb
#
# Test suite for the Daemon class
#########################################################################
if File.basename(Dir.pwd) == "test"
	require "ftools"
	Dir.chdir ".."
	Dir.mkdir("win32") unless File.exists?("win32")
   	File.copy("service.so","win32")
   	$LOAD_PATH.unshift Dir.pwd
end

require "win32/service"
require "test/unit"
include Win32

class TC_Daemon < Test::Unit::TestCase
   def setup
      @d = Daemon.new
   end
   
   def test_version
      assert_equal("0.5.0",Daemon::VERSION)
   end
   
   def test_constructor
      assert_respond_to(Daemon, :new)
      assert_nothing_raised{ Daemon.new }
      assert_raises(ArgumentError){ Daemon.new(1) } # No arguments by default
   end
   
   def test_mainloop
      assert_respond_to(@d, :mainloop)
   end
   
   def test_constants
      assert_not_nil(Service::CONTINUE_PENDING)
      assert_not_nil(Service::PAUSE_PENDING)
      assert_not_nil(Service::PAUSED)
      assert_not_nil(Service::RUNNING)
      assert_not_nil(Service::START_PENDING)
      assert_not_nil(Service::STOP_PENDING)
      assert_not_nil(Service::STOPPED) 
   end
   
   def teardown
      @d = nil
   end
end