############################################################################
# daemon_test.rb
#
# This is a command line script for installing and/or running a small
# Ruby program as a service.  The service will simply write a small
# bit of text to a file every 3 seconds.  It will also write some text to
# a file during the initialization step.
#
# It should take about 10 seconds to start, which is intentional - it's a test
# of the service_init hook, so don't be surprised if you see "one moment, start
# pending" about 10 times on the command line.
#
# The two files in question are C:\test.log and C:\test2.log.  Feel free to
# delete these when finished.
#
# To run the service, you must install it first.
#
# Usage: ruby daemontest.rb <option>
#
# Note that you *must* pass this program an option
#
# Options:
#    install    - Installs the service.  The service name is "AbbaSvc"
#                 and the display name is "Abba".
#    start      - Starts the service.  Make sure you stop it at some point or
#                 you will eventually fill up your filesystem!.
#    stop       - Stops the service.
#    pause      - Pauses the service.
#    resume     - Resumes the service.
#    uninstall  - Uninstalls the service.
#    delete     - Same as uninstall.
#
# You can also used the Win32 Services gui to start and stop the service.
# Start -> Control Panel -> Administrative Tools -> Services
############################################################################
require "win32/service"
include Win32

puts "VERSION: " + Service::VERSION

# I start the service name with an 'A' so that it appears at the top
SERVICE_NAME = "AbbaSvc"
SERVICE_DISPLAYNAME = "Abba"

if ARGV[0] == "install"
    svc = Service.new
    svc.create_service{ |s|
       s.service_name = SERVICE_NAME
       s.display_name = SERVICE_DISPLAYNAME
       s.binary_path_name = 'ruby ' + File.expand_path($0)
       s.dependencies = []
    }
    svc.close
    puts "installed"
elsif ARGV[0] == "start"
    Service.start(SERVICE_NAME)
    started = false
    while started == false
    	s = Service.status(SERVICE_NAME)
    	started = true if s.current_state == "running"
    	break if started == true
    	puts "One moment, " + s.current_state
    	sleep 1
    end
    puts "Ok, started"
elsif ARGV[0] == "stop"
    Service.stop(SERVICE_NAME)
	stopped = false
	while stopped == false
		s = Service.status(SERVICE_NAME)
		stopped = true if s.current_state == "stopped"
		break if stopped == true
		puts "One moment, " + s.current_state
		sleep 1
	end
    puts "Ok, stopped"
elsif ARGV[0] == "uninstall" || ARGV[0] == "delete"
    begin
      Service.stop(SERVICE_NAME)
    rescue
    end
    Service.delete(SERVICE_NAME)
    puts "deleted"
elsif ARGV[0] == "pause"
    Service.pause(SERVICE_NAME)
	paused = false
	while paused == false
		s = Service.status(SERVICE_NAME)
		paused = true if s.current_state == "paused"
		break if paused == true
		puts "One moment, " + s.current_state
		sleep 1
	end
    puts "Ok, paused"
elsif ARGV[0] == "resume"
    Service.resume(SERVICE_NAME)
	resumed = false
	while resumed == false
		s = Service.status(SERVICE_NAME)
		resumed = true if s.current_state == "running"
		break if resumed == true
		puts "One moment, " + s.current_state
		sleep 1
	end
    puts "Ok, resumed"
else

   if ENV["HOMEDRIVE"]!=nil
     puts "No option provided.  You must provide an option.  Exiting..."
     exit
   end

   ## SERVICE BODY START
   class Daemon
      # A real program would use file locking here.
      def service_stop
         File.open("c:\\test.log","a+"){ |f|
            f.puts "stop signal received: " + Time.now.to_s
         }
      end

      def service_pause
         File.open("c:\\test.log","a+"){ |f|
            f.puts "pause signal received: " + Time.now.to_s
         }
      end

      def service_resume
         File.open("c:\\test.log","a+"){ |f|
            f.puts "continue/resume signal received: " + Time.now.to_s
         }
      end
      
      # Added in 0.5.0
      def service_init
         for i in 1..20
            File.open("c:\\test2.log","a+"){ |f| f.puts("#{i}") }
            sleep 1
         end
      end

      ## worker function
      def service_main
         File.open("c:\\test.log","a+") { |f| f.puts("service_main entered") }
         begin
            while state == RUNNING || state == PAUSED
               while state == RUNNING
                  sleep 3
                  msg = "service is running as of: " + Time.now.to_s
                  File.open("c:\\test.log","a+") { |f| f.puts msg }
               end
               if state == PAUSED
                  msg = "service is paused as of: " + Time.now.to_s
                  File.open("c:\\test.log","a+") { |f| f.puts msg }
                     while state == PAUSED
                        sleep 3            # do nothing
                     end
               end
            end
            File.open("c:\\test.log","a+"){ |f| f.puts("service_main left") }
         rescue StandardError, Interrupt => e
            File.open("c:\\test.log","a+"){ |f| f.puts("ERROR: #{e}") }
         end
      end
   end

   d = Daemon.new
   d.mainloop

end #if



