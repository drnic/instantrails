#!/usr/bin/env ruby

require 'stringio'
require 'yaml'
require 'digest/sha1'
require 'socket'
require 'cgi'
require 'monitor'
require 'singleton'
require 'drb'
require 'set'


module SCGI

    
    # A factory that makes Log objects, making sure that one Log is associated
    # with each log file.  I avoid Logger as it's in a state of flux.
    class LogFactory < Monitor
        include Singleton
        
        def initialize
            super()
            @@logs = {}
        end
        
        def create(file)
            result = nil
            synchronize do
                result = @@logs[file]
                if not result
                    result = Log.new(file)
                    @@logs[file] = result
                end
            end
            return result
        end
    end
    
    # A simple Log class that has an info and error method for output
    # messages to a log file.  The main thing this logger does is 
    # include the process ID in the logs so that you can see which child
    # is creating each message.
    class Log < Monitor
        def initialize(file)
            super()
            @out = open(file, "a+")
            @out.sync = true
            @pid = Process.pid
            @info = "[INF][#{Process.pid}] "
            @error = "[ERR][#{Process.pid}] "
        end
        
        def info(msg)
            synchronize do
                @out.print @info, msg,"\n"
            end
        end
        
        # If an exception is given then it will print the exception and a stack trace.
        def error(msg, exc=nil)
            if exc
                synchronize do
                    @out.print @error, "#{msg}: #{exc}\n"
                    @out.print @error, exc.backtrace.join("\n"), "\n"
                end
            else
                synchronize do
                    @out.print @error, msg,"\n"
                end
            end
        end
    end
    
    
    # Modifies CGI so that we can use it.  Main thing it does is expose
    # the stdinput and stdoutput so SCGI::Processor can connect them to
    # the right sources.  It also exposes the env_table so that SCGI::Processor
    # and hook the SCGI parameters into the environment table.
    #
    # This is partially based on the FastCGI code, but much of the Ruby 1.6 
    # backwards compatibility is removed.
    class CGIFixed < ::CGI
        public :env_table
    
        def initialize(params, data, out, *args)
            @env_table = params
            @args = *args
            @input = StringIO.new(data)
            @out = out
            super(*args)
        end
        
        def args
            @args
        end
        
        def env_table
            @env_table
        end
        
        def stdinput
            @input
        end
        
        def stdoutput
            @out
        end
    end


    # This is the complete guts of the SCGI system.  It is designed so that
    # people can take it and implement it for their own systems, not just 
    # Ruby on Rails.  This implementation is not complete since you must
    # create your own that implements the process_request method.
    #
    # The SCGI::Processor is designed to be as fast as possible under Ruby 1.8.2
    # without sacrificing simplicity.  This one class is actually the entire
    # SCGI core and is the result of careful analysis and performance tuning.
    # Be very concious of how you change things before you do it, and do a 
    # performance test before and AFTER you make change to confirm that it 
    # actually runs faster.
    #
    # The SCGI protocol only works with TCP/IP sockets and not domain sockets.
    # It might be useful for shared hosting people to have domain sockets, but
    # they aren't supported in Apache, and in lighttpd they're unreliable.
    # Also, domain sockets don't work so well on Windows.
    #
    class Processor < Monitor
        attr_reader :settings
     
        # The settings come from a YAML file which is usually created by the SCGI::Configuration
        # class.  Not all configuration settings are used by SCGI::Processor.  The ones used are
        # are:  :logfile, :maxconns, :host, :port, :throttle.
        def initialize(settings = {})
            @total_conns = 0
            @shutdown = false
            @dead = false
            @threads = Queue.new
            super()

            configure(settings)
        end
    
        # Used internally during initialize, and also called by SCGI::Controller
        # to force the SCGI::Processor to reload it's configuration.  This
        # reconfigure will only reload the :maxconns and :throttle settings
        # since those are the only ones that can be soft loaded.  Other
        # configurations require a restart.
        def configure(settings)
            @settings = settings
            @log = LogFactory.instance.create(settings[:logfile] || "log/scgi.log")
            @maxconns = settings[:maxconns] || 2**30-1
            @started = Time.now
            @host = settings[:host] || "127.0.0.1"
            @port = settings[:port] || "9999"
            
            @throttle_sleep = 1.0/settings[:throttle].to_f if settings[:throttle]
        end
        
        # Starts the SCGI::Processor having it listen on either the
        # given socket or listening to a new socket on the @host/@port
        # configured.  The option to give listen a socket is there so
        # that others can create one socket, and then fork several processors
        # to listen to it.  This forked listening does work, but there were
        # reports that it wasn't reliable so I've removed it from the 
        # SCGI Rails Runner project.
        #
        # This function does not return until a shutdown.
        def listen(socket = nil)
            if socket
                @socket = socket
            else
                @socket = TCPServer.new(@host, @port)
            end

            # we also need a small collector thread that does nothing
            # but pull threads off the thread queue and joins them
            @collector = Thread.new do
                while t = @threads.shift
                    collect_thread(t)
                    @total_conns += 1
                end
            end
            
            thread = Thread.new do
                while true
                    handle_client(@socket.accept)
                    sleep @throttle_sleep if @throttle_sleep
                    break if @shutdown and @threads.length <= 0
                end
            end
            
            # and then collect the listener thread which blocks until it exits
            collect_thread(thread)
            
            @socket.close if not @socket.closed?
            @dead = true
            @log.info("Exited accept loop. Shutdown complete.")
        end
    
        
        def collect_thread(thread)
            begin
                thread.join
            rescue Interrupt
                @log.info("Shutting down from SIGINT.")
            rescue IOError
                @log.error("received IOError #$!.  Web server may possibly be configured wrong.")
            rescue Object
                @log.error("Collecting thread", $!)
            end
        end
        
        
        # Internal function that handles a new client connection.
        # It spawns a thread to handle the client and registers it in the 
        # @threads queue.  A collector thread is responsible for joining these
        # and clearing them out.  This design is needed because Ruby's GC
        # doesn't seem to deal with threads as well as others believe.
        #
        # Depending on how your system works, you may need to synchronize 
        # inside your process_request implementation.  The scgi_service
        # script for Ruby on Rails does this so that Rails will run
        # as if it were single threaded.
        #
        # It also handles calculating the current and total connections,
        # and deals with the graceful shutdown.  The important part 
        # of graceful shutdown is that new requests get redirected to
        # the /busy.html file.
        #
        def handle_client(socket)
            # ruby's GC seems to do weird things if we don't assign the thread to a local variable
            @threads << Thread.new do
                begin
                    len = ""
                    # we only read 10 bytes of the length.  any request longer than this is invalid
                    while len.length <= 10
                        c = socket.read(1)
                        if c == ':'
                            # found the terminal, len now has a length in it so read the payload
                            break
                        else
                            len << c
                        end
                    end
                    
                    # we should now either have a payload length to get
                    payload = socket.read(len.to_i)
                    if (c = socket.read(1)) != ','
                        @log.error("Malformed request, does not end with ','")
                    else
                        read_header(socket, payload)
                    end
                rescue Object
                    @log.error("Handling client", $!)
                ensure
                    # no matter what we have to put this thread on the bad list
                    socket.close if not socket.closed?
                end
            end
        end

    
        # Does three jobs:  reads and parses the SCGI netstring header,
        # reads any content off the socket, and then either calls process_request
        # or immediately returns a redirect to /busy.html for some connections.
        #
        # The browser/connection that will be redirected to /busy.html if 
        # either SCGI::Processor is in the middle of a shutdown, or if the
        # number of connections is over the @maxconns.  This redirect is
        # immediate and doesn't run your system, so it will happen with
        # much less processing and help keep your system responsive.
        def read_header(socket, payload)
            return if socket.closed?
            request = Hash[*(payload.split("\0"))]
            if request["CONTENT_LENGTH"]
                length = request["CONTENT_LENGTH"].to_i
                if length > 0
                    body = socket.read(length)
                else
                    body = ""
                end

                if @shutdown or @threads.length > @maxconns
                    socket.write("Location: /busy.html\r\n")
                    socket.write("Cache-control: no-cache, must-revalidate\r\n")
                    socket.write("Expires: Mon, 26 Jul 1997 05:00:00 GMT\r\n")
                    socket.write("Status: 307 Temporary Redirect\r\n\r\n")
                else
                    process_request(request, body, socket)
                end
            end
        end

    
        # You must implement this yourself.  The request is a Hash
        # of the CGI parameters from the webserver.  The body is the
        # raw CGI body.  The socket is where you write your results
        # (properly HTTP formatted) back to the webserver.
        def process_request(request, body, socket)
            raise "You must implement process_request"
        end
        
        
        # Returns a Hash with status information.  This is used
        # by the SCGI::Controller to give status.
        def status
            { 
            :time => Time.now,  :pid => Process.pid, :settings => @settings,
            :env => @settings[:env], :started => @started,
            :max_conns => @maxconns, :conns => @threads.length, :systimes => Process.times,
            :throttle => @throttle, :shutdown => @shutdown, :dead => @dead, :total_conns => @total_conns
            }
        end
        
        
        # When called it will set the @shutdown flag indicating to the 
        # SCGI::Processor.listen function that all new connections should
        # be set to /busy.html, and all current connections should be 
        # "valved" off.  Once all the current connections are gone the
        # SCGI::Processor.listen function will exit.
        #
        # Use the force=true parameter to force an immediate shutdown.
        # This is done by closing the listening socket, so it's rather
        # violent.
        def shutdown(force = false)
            synchronize do
                @shutdown = true;
                
                if @threads.length == 0 
                    @log.info("Immediate shutdown since nobody is connected.")
                    @socket.close
                elsif force
                    @log.info("Forcing shutdown.  You may see exceptions.")
                    @socket.close
                else
                    @log.info("Shutdown requested.  Beginning graceful shutdown with #{@threads.length} connected.")
                end
            end
        end        
    end
    
        
        
    # SCGI::Controller implements a DRb and POSIX signals control system for
    # a running SCGI::Processor.  It *should* work for any system, not just
    # Ruby on Rails.  All it requires is an already configured SCGI::Processor
    # and it then exposes the proper control methods.
    #
    # It uses several options from SCGI::Processor.settings to configure itself.
    # It uses :disable_signals and :disable_drb to determine whether to disable
    # those.  It will configure DRb based on :control_url setting.  Finally, it
    # will use the log file configured with :log_file.
    #
    # The POSIX signals and DRb control methods are configurable since some people
    # may need to disable them in different hosting situations.  For example, if
    # you are on a hosting provider that has all processes under the nobody user, then
    # signals are a *very* bad idea since anyone can control your application.
    # If you're in an environment that requires you to register ports you want, then
    # DRb may be too much of a pain in the ass.  If you're doubly screwed and have
    # a hosting provider with a single nobody user AND requires you to register ports
    # then you can disable both, but you should also look at switching hosting providers.
    #
    # Restart is implemented outside the Controller.  What happens is when it receives
    # restart request it will set the SCGI::Controller.restart_requested to true.
    # The script that uses SCGI::Controller should check this variable, and if it's
    # true then it should do an exec to create a new ruby running your application again.
    class Controller
        attr_reader :restart_requested
        
        # Given an SCGI:Processor it will configure things in preparation for
        # the SCGI::Controller.run call.
        def initialize(processor)
            @processor = processor
            @restart_requested = false
            @log = SCGI::LogFactory.instance.create(@processor.settings[:log_file] || "log/scgi.log")
        end
    
        # Sets up the POSIX signals (unless disabled) and the DRb server (unless disabled)
        # and then starts the processor with SCGI::Processor.listen.  The signals available
        # are:
        #
        # * TERM -- Forced shutdown.
        # * INT -- Graceful shutdown.
        # * HUP -- Graceful restart (no forced).
        # * USR1 -- Soft reconfigure (reloads config file).
        # * USR2 -- Dumps status info to the logs.  Super ugly.
        def run
            if not @processor.settings[:disable_signals]
                trap("TERM") { @log.info("SIGTERM, forced shutdown."); @processor.shutdown(force=true) }
                trap("INT") { @log.info("SIGINT, graceful shtudown started."); @processor.shutdown }
                trap("HUP") { @log.info("SIGHUP, restart started."); @restart_requested = true; @processor.shutdown  }
                trap("USR1") { @log.info("SIGUSR1, soft reconfigure."); @processor.configure(config) }
                trap("USR2") { @log.info(@processor.status.to_yaml) }
            else
                @log.info("POSIX signal control disabled.")
            end

            if not @processor.settings[:disable_drb]
                secure_drb_methods(["status","reconfigure","shutdown","restart"])
                DRb.start_service(@processor.settings[:control_url], self)
            else
                @log.info("Network (DRb) control disabled.")
            end
            
            if @processor.settings[:disable_drb] and @processor.settings[:disable_signals]
                @log.info("WARNING! You have disabled all methods of control.  Hope you know your stuff.")
            end
            
            @log.info("Running in #{@processor.settings[:env]} mode on #{@processor.settings[:host]}:#{@processor.settings[:port]}")
            @processor.listen
        end
    
        # Returns status from the SCGI::Processor if the given password is valid.
        # This method is usually called by a DRb client.
        def status(password)
            verify_password(password)
            @processor.status
        end

        # Reconfigures the SCGI::Processor if the given password is valid.
        # This method is usually called by a DRb client.
        def reconfigure(password)
            verify_password(password)
            @log.info("Reconfiguring...")
            @processor.configure(config)
            @log.info("Done.")
            return true
        end

        # Does a forced or graceful shutdown if the given password is valid.
        # This method is usually called by a DRb client.
        def shutdown(password, force = false)
            verify_password(password)
            @processor.shutdown(force)
        end

        # Does a restart if the given password is valid.  It sets the SCGI::Controller.restart_requested
        # to true and then starts the graceful shutdown process.
        # This method is usually called by a DRb client.
        def restart(password, force = true)
            verify_password(password)
            @restart_requested = true
            @log.info("Restart requested, will restart after shutdown.")
            @processor.shutdown(force)
        end
    
        private

        # Uses the crypt method and the password image from the config
        # file to verify the password.  It pulls the first two characters
        # off the image as the salt and then compares the resulting crypt
        # output to the stored password image.  This makes it about as
        # secure as old school unix passwords.
        def verify_password(password)
            image = @processor.settings[:password]
            pc = password.crypt(image[0..2])
            if pc != image
                raise "Authentication failed"
            end
        end
    
        # DRb only allows blacklist exclusion, which is super bad.  What we
        # really need is "ALLOW_ONLY_METHODS".  This method does that by listing
        # all the methods this object has, then removing the methods listed in
        # allowed_methods.  What remains is a block list for everything else which
        # we configure in DRb::DRbServer::INSECURE_METHODS.
        def secure_drb_methods(allowed_methods)
            all_methods = self.methods
            bad_methods = all_methods - allowed_methods
        
            DRb::DRbServer::INSECURE_METHOD << bad_methods.to_a
            DRb::DRbServer::INSECURE_METHOD.flatten!
        end
    end
    
    # The default configuration file is simple config/scgi.yaml.
    DEFAULT_CONFIG = "config/scgi.yaml"
    
    # A simple client that hooks up the passwords and other configurations
    # needed to communicate with a SCGI::Controller over DRb.
    class ControlClient

        # The settings param is a hash usually taken from the user as command line
        # arguments.  These will override the YAML file at config_path.
        def initialize(settings, config_path, control_url, password)
            @config_path = config_path || DEFAULT_CONFIG
            @password = password
            @config = YAML.load_file(@config_path)
            @settings = settings
            @control_url = control_url || @settings[:control_url] || @config[:control_url]
            @client = DRbObject.new(nil, @control_url)
        end         
        
        # Returns the status from the DRb server.  Throws an exception if the 
        # password is wrong (which comes from the DRb server).
        def status
            return @client.status(@password)
        end

        # Tells the SCGI::Controller to reconfigure.  Throws an exception if the 
        # password is wrong (which comes from the DRb server).
        def reconfigure
            @client.reconfigure(@password)
        end

        # Starts the graceful or forced shutdown.  Throws an exception if the 
        # password is wrong (which comes from the DRb server).
        def stop
            @client.shutdown(@password, @settings[:force] || false)
        end

        # Does the graceful or forced restart.  Throws an exception if the 
        # password is wrong (which comes from the DRb server).
        def restart
            @client.restart(@password, @settings[:force] || false)
        end
    end

    
    # Deals with the process of creating a configuration file
    # that has reasonable default options.  The default options
    # are:
    #
    # * :env => "production",
    # * :host => "127.0.0.1",
    # * :port => 9999,
    # * :logfile => "log/scgi.log",
    # * :config => DEFAULT_CONFIG
    # * :control_url => "druby://127.0.0.1:#{settings[:port].to_i-1000}"
    # * :throttle => not set
    # * :maxconns => not set
    class Configuration

        # Sets up defaults with the given settings Hash overriding 
        # any defaults.
        def initialize(settings)
            @settings = defaults(settings)
        end

        # Creates the salted password and writes the resulting 
        # YAML configurqation file.
        def configure
            salting = ('a' .. 'z').to_a + ('A' .. 'Z').to_a + ('0' .. '9').to_a
            @settings[:password] = @settings[:password].crypt(salting[rand(salting.length)] + salting[rand(salting.length)])
            open(@settings[:config],"w") {|f| f.write(YAML.dump(@settings)) }
        end

        
        # Sets up the defaults.
        def defaults(settings)
            defaults = nil
            if settings[:merge]
                UI.say("Merging with previous settings.")
                defaults = YAML.load_file(settings[:config] || DEFAULT_CONFIG)
            else
                defaults = {
                :env => "production",
                :host => "127.0.0.1",
                :port => 9999,
                :logfile => "log/scgi.log",
                :config => $config_path || DEFAULT_CONFIG }
            end

            settings = defaults.merge(settings)
            # fix up the stuff that's not quite right yet
            settings[:control_url] = "druby://127.0.0.1:#{settings[:port].to_i-1000}"
            settings[:port] = settings[:port].to_i
            settings[:throttle] = settings[:throttle].to_i if settings[:throttle]
            settings[:maxconns] = settings[:maxconns].to_i if settings[:maxconns]
    
            return settings
        end
        
    end
    
    
    # Used to do a simple start of the application.  It will change to a
    # directory before running the application.  It currently uses a simple
    # fork/exec to start the processor, but this won't work on windows.
    class Kicker
        def initialize(config_path, run_path)
            @config_path = config_path || DEFAULT_CONFIG
            @run_path = run_path || "."
            @settings = YAML.load_file(@config_path)
        end
        
        # Starts using the given command and returns the PID of the
        # newly started process.  Usually the cmd is the scgi_service
        # script, but people reusing this code in their system might
        # have a different command name.
        def start(cmd)
            pid = nil
            
            Dir.chdir @run_path do
                pid = fork do
                    exec "ruby", cmd, @config_path
                end
            end
            
            return pid
        end
    end
    
end
