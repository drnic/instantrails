###########################################################################
# tc_service.rb
#
# Test suite for Win32::Service.  Note that this test suite will take
# a few seconds to run.  There are some 'sleep' calls sprinkled throughout
# this code.  These are necessary for some of the methods to complete
# before subsequent tests are run.
###########################################################################

info = <<HERE
   This test will stop and start your Clipboard service, as well as pause and
   resume your Schedule service.  This is harmless unless you are actually
   using these services at the moment you run this test.  Is it OK to
   proceed? (y/N)
HERE

puts info
ans = STDIN.gets.chomp.downcase
unless ans == "y"
   	puts "Exiting without running test suite..."
   	exit!
end

base = File.basename(Dir.pwd)
if base == "test" || base =~ /win32-service/
	require "ftools"
	Dir.chdir("..") if base == "test"
	Dir.mkdir("win32") unless File.exists?("win32")
   	File.copy("service.so","win32")
   	$LOAD_PATH.unshift Dir.pwd
   	Dir.chdir("test") unless base == "test"
end

puts "This will take a few seconds.  Be patient..."

require "test/unit"
require "win32/service"
require "socket"
include Win32

class TC_Win32Service < Test::Unit::TestCase
   def setup
      @service = Service.new
      @stop_start_service = "ClipSrv"
      @pause_resume_service = "Schedule"
      @ver = `ver`.strip.chop.split.last.split(".")[0..1].join(".").to_f
      
      # Not to panic - we don't stop or disable these services in this test.
      # These are only used for getting the service name and display name.
      @dname = "Remote Procedure Call (RPC)"
      @sname = "dmadmin"
   end
   
   def test_version
      assert_equal("0.5.0", Service::VERSION, "Bad version")
   end
   
   def test_class_type
      assert_kind_of(Win32::Service, @service)
   end
   
   def test_machine_name
      assert_respond_to(@service, :machine_name)
      assert_respond_to(@service, :machine_name=)
      assert_nothing_raised{ @service.machine_name }
      assert_nothing_raised{ @service.machine_name = Socket.gethostname }
   end
   
   def test_machine_name_expected_errors
      assert_raises(ArgumentError){ @service.machine_name(1) }
   end
   
   def test_service_name
      assert_respond_to(@service, :service_name)
      assert_respond_to(@service, :service_name=)
      assert_nothing_raised{ @service.service_name }
      assert_nothing_raised{ @service.service_name = "foo" }
   end
   
   def test_service_name_expected_errors
      assert_raises(ArgumentError){ @service.service_name(1) }
   end
   
   def test_display_name
      assert_respond_to(@service, :display_name)
      assert_respond_to(@service, :display_name=)
      assert_nothing_raised{ @service.display_name }
      assert_nothing_raised{ @service.display_name = "foosvc" }
   end
   
   def test_display_name_expected_errors
      assert_raises(ArgumentError){ @service.display_name(1) }
   end
   
   def test_binary_path_name
      assert_respond_to(@service, :binary_path_name)
      assert_respond_to(@service, :binary_path_name=)
      assert_nothing_raised{ @service.binary_path_name }
      assert_nothing_raised{ @service.binary_path_name = "C:/foo/bar" }
   end
   
   def test_binary_path_name_expected_errors
      assert_raises(ArgumentError){ @service.binary_path_name(1) }
   end
   
   def test_load_order_group
      assert_respond_to(@service, :load_order_group)
      assert_respond_to(@service, :load_order_group=)
      assert_nothing_raised{ @service.load_order_group }
      assert_nothing_raised{ @service.load_order_group = "foo" }
   end
   
   def test_load_order_group_expected_errors
      assert_raises(ArgumentError){ @service.load_order_group(1) }
   end
   
   def test_dependencies
      assert_respond_to(@service, :dependencies)
      assert_respond_to(@service, :dependencies=)     
      assert_nothing_raised{ @service.dependencies = ["foo","bar"] }
   end
   
   def test_dependencies_expected_errors
      assert_raises(ArgumentError){ @service.dependencies(1) }
      assert_raises(TypeError){ @service.dependencies = "foo" }
      assert_raises(TypeError){ @service.dependencies = 1 }
   end
   
   def test_start_name
      assert_respond_to(@service, :start_name)
      assert_respond_to(@service, :start_name=)
      assert_nothing_raised{ @service.start_name }
      assert_nothing_raised{ @service.start_name = "foo" }
   end
   
   def test_start_name_expected_errors
      assert_raises(ArgumentError){ @service.start_name(1) }
   end
   
   def test_password
      assert_respond_to(@service, :password)
      assert_respond_to(@service, :password=)
      assert_nothing_raised{ @service.password }
      assert_nothing_raised{ @service.password = "mypass" }
   end
   
   def test_password_expected_errors
      assert_raises(ArgumentError){ @service.password(1) }
   end
   
   def test_error_control
      assert_respond_to(@service, :error_control)
      assert_respond_to(@service, :error_control=)
      assert_nothing_raised{ @service.error_control }
      assert_nothing_raised{ @service.error_control = "test" }
   end
   
   def test_error_control_expected_errors
      assert_raises(ArgumentError){ @service.error_control(1) }
   end
   
   def test_start_type
      assert_respond_to(@service, :start_type)
      assert_respond_to(@service, :start_type=)
      assert_nothing_raised{ @service.start_type }
      assert_nothing_raised{ @service.start_type = Service::DEMAND_START }
   end
   
   def test_start_type_expected_errors
      assert_raises(ArgumentError){ @service.start_type(1) }
   end
   
   def test_desired_access
      assert_respond_to(@service, :desired_access)
      assert_respond_to(@service, :desired_access=)
      assert_nothing_raised{ @service.desired_access }
      assert_nothing_raised{ @service.desired_access = Service::MANAGER_LOCK }
   end
   
   def test_desired_access_expected_errors
      assert_raises(ArgumentError){ @service.desired_access(1) }
   end
   
   def test_service_type
      assert_respond_to(@service, :service_type)
      assert_respond_to(@service, :service_type=)
      assert_nothing_raised{ @service.service_type }
      assert_nothing_raised{
         @service.service_type = Service::WIN32_OWN_PROCESS
      }
   end
   
   def test_service_type_expected_errors
      assert_raises(ArgumentError){ @service.service_type(1) }
   end
   
   def test_constructor_arguments
      assert_nothing_raised{ Service.new }
      assert_nothing_raised{ Service.new(Socket.gethostname) }
      assert_nothing_raised{
         Service.new(Socket.gethostname, Service::MANAGER_ALL_ACCESS)
      }
   end
   
   def test_constructor_expected_errors
      assert_raises(ArgumentError){ Service.new("test",1,1) }
      assert_raises(TypeError){ Service.new(1) }
   end
   
   def test_services
      assert_respond_to(Service, :services)
      assert_nothing_raised{ Service.services{ } }
      assert_nothing_raised{ Service.services }
      assert_kind_of(Array, Service.services)
      assert_kind_of(Struct::Win32Service, Service.services.first)
   end
   
   def test_services_expected_errors
      assert_raises(TypeError){ Service.services(1) }
   end
   
   # This test will fail if the Network DDE service is not running.  The
   # sleep calls are to help ensure that the service is actually started
   # and stopped (because it doesn't necessarily happen instantly).
   def test_start_stop
      assert_nothing_raised{ Service.start(@stop_start_service) }
      sleep 2
      assert_nothing_raised{ Service.stop(@stop_start_service) }
      sleep 2
      assert_nothing_raised{ Service.start(@stop_start_service, nil, "foo") }
      sleep 2
      assert_nothing_raised{ Service.stop(@stop_start_service) }
      sleep 2
   end

   def test_start_failure
      assert_raises(ServiceError){ Service.start("bogus") }
      assert_raises(ServiceError){ Service.start("winmgmt") }
   end
   
   def test_stop_failure
      assert_raises(ServiceError){ Service.stop("bogus") }
      assert_raises(ServiceError){ Service.stop("ClipSrv") }
   end
   
   def test_pause_failure
      assert_raises(ServiceError){ Service.pause("bogus") }
      assert_raises(ServiceError){ Service.pause("ClipSrv") }
   end
   
   def test_resume_failure
      assert_raises(ServiceError){ Service.resume("bogus") }
      assert_raises(ServiceError){ Service.resume("ClipSrv") }
   end
   
   def test_pause_resume
      assert_nothing_raised{ Service.pause(@pause_resume_service) }
      sleep 2
      assert_nothing_raised{ Service.resume(@pause_resume_service) }
      sleep 2
   end
   
   def test_getservicename
      assert_respond_to(Service, :getservicename)
      assert_nothing_raised{ Service.getservicename(@dname) }
      assert_kind_of(String, Service.getservicename(@dname))
   end
   
   def test_getdisplayname
      assert_respond_to(Service, :getdisplayname)
      assert_nothing_raised{ Service.getdisplayname(@sname) }
      assert_kind_of(String, Service.getdisplayname(@sname))
   end
   
   def test_create_delete
      assert_nothing_raised{
         @service.create_service{ |s|
            s.service_name = "foo"
            s.display_name = "Foo Test"
            s.binary_path_name = "C:\\ruby\\bin\\rubyw.exe -v"
         }
      }
      sleep 2
      assert_nothing_raised{ Service.delete("foo") }
      sleep 2
      assert_raises(ServiceError){ Service.delete("foo") }
   end
   
   def test_configure_service
      assert_nothing_raised{
         @service.configure_service{ |s|
            s.service_name = "ClipSrv"
            s.display_name = "Clippy"
         }
      }
      sleep 2
      assert_nothing_raised{
         @service.configure_service{ |s|
            s.service_name = "ClipSrv"
            s.display_name = "ClipBook"
         }
      }  
   end
   
   def test_status
      members = %w/service_type current_state controls_accepted/
      members.push(%w/win32_exit_code service_specific_exit_code/)
      members.push(%w/check_point wait_hint interactive?/)
      if @ver >= 5
         members.push(%w/pid service_flags/)
      end
      members.flatten!
      
      assert_nothing_raised{ Service.status("ClipSrv") }
      struct = Service.status("ClipSrv")
      assert_kind_of(Struct::Win32ServiceStatus, struct)
      assert_equal(members, struct.members)
   end 
   
   def test_constants
      assert_not_nil(Service::MANAGER_ALL_ACCESS)
      assert_not_nil(Service::MANAGER_CREATE_SERVICE)
      assert_not_nil(Service::MANAGER_CONNECT)
      assert_not_nil(Service::MANAGER_ENUMERATE_SERVICE)
      assert_not_nil(Service::MANAGER_LOCK)
      #assert_not_nil(Service::MANAGER_BOOT_CONFIG)
      assert_not_nil(Service::MANAGER_QUERY_LOCK_STATUS)
      
      assert_not_nil(Service::FILE_SYSTEM_DRIVER)
      assert_not_nil(Service::KERNEL_DRIVER)
      assert_not_nil(Service::WIN32_OWN_PROCESS)
      assert_not_nil(Service::WIN32_SHARE_PROCESS)
      assert_not_nil(Service::INTERACTIVE_PROCESS)
      
      assert_not_nil(Service::AUTO_START)
      assert_not_nil(Service::BOOT_START)
      assert_not_nil(Service::DEMAND_START)
      assert_not_nil(Service::DISABLED)
      assert_not_nil(Service::SYSTEM_START)
      
      assert_not_nil(Service::ERROR_IGNORE)
      assert_not_nil(Service::ERROR_NORMAL)
      assert_not_nil(Service::ERROR_SEVERE)
      assert_not_nil(Service::ERROR_CRITICAL)
      
      assert_not_nil(Service::CONTINUE_PENDING)
      assert_not_nil(Service::PAUSE_PENDING)
      assert_not_nil(Service::PAUSED)
      assert_not_nil(Service::RUNNING)
      assert_not_nil(Service::START_PENDING)
      assert_not_nil(Service::STOP_PENDING)
      assert_not_nil(Service::STOPPED)      
   end
   
   def test_exists
      assert_nothing_raised{ Service.exists?("ClipSrv") }
      assert_raises(ArgumentError){ Service.exists? }
      assert_equal(true, Service.exists?("ClipSrv"))
      assert_equal(false, Service.exists?("foobar"))
   end
   
   def teardown
      begin
         @service.close
      rescue ServiceError
         # Ignore - not sure why this happens
      end
      @service = nil
   end
end