#####################################################################
# services_test.rb
#
# Test script for general futzing.  Comment or uncomment code bits
# as you see fit.
#####################################################################
base = File.basename(Dir.pwd)
if base == "examples" || base =~ /win32-service/
	require "ftools"
	Dir.chdir("..") if base == "examples"
	Dir.mkdir("win32") unless File.exists?("win32")
	File.copy("service.so","win32")
	$LOAD_PATH.unshift Dir.pwd
end

require "win32/service"
require "pp"
include Win32

puts "VERSION: " + Service::VERSION.to_s
sleep 1

p Service.exists?("ClipSrv")
p Service.exists?("foo")

#s = Service.status("ClipSrv")
#p s.class

Service.services{ |struct|
   pp struct
}

#svc = Service.new

=begin
svc.create_service{ |s|
   s.service_name = "foo"
   s.display_name = "AFoo"
   s.binary_path_name = "C:\\ruby\\bin\\rubyw.exe -v"
   s.dependencies = ["ClipSrv"]
}

puts "foo created"
=end

=begin
svc.configure_service{ |s|
   s.service_name = "foo"
   s.display_name = "ABar"
   s.dependencies = []
}
puts "foo configured"
=end

#svc.close

#Service.start("ClipSrv")
#puts "Service 'foo' deleted"

=begin
# Note that this service won't actually *run*, but it will be created.
s = Service.new(
   :service_name => "foo",
   :display_name => "AFoo",
   :binary_path_name => "C:\\ruby\\bin\\rubyw.exe -v"
)

s.create_service
sleep 2
puts "Service 'foo' created.  Display name is 'AFoo'"

Service.delete(s.service_name)
sleep 2
puts "Service 'foo' deleted"

Service.stop("ClipSrv")
sleep 2
puts "Service 'ClipSrv' stopped"

Service.start("ClipSrv")
sleep 2
puts "Service 'ClipSrv' started"

Service.pause("Schedule")
sleep 2
puts "Service 'Schedule' Paused"

Service.resume("Schedule")
sleep 2
puts "Service 'Schedule' Resumed"

dname = "Remote Procedure Call (RPC)"
sname = "ClipSrv"

puts "Service name for #{dname} is: " + Service.getservicename(dname)
puts "Display name for #{sname} is: " + Service.getdisplayname(sname)

Service.services{ |s|
   p s
   puts
}
=end