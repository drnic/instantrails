# A small piece of code to prepare the script
# for 'script running' from FreeRIDE
BEGIN {

  # redirecting STDERR to STDOUT to keep output 
  # synchronized on the FreeRIDE side.
  STDERR.reopen(STDOUT)
  STDOUT.sync = true
  STDERR.sync = true

}

END {
  unless $!.kind_of? SystemExit
    # for some reason on Win32 the exception doesn't show up
    # before the "press ENTER..." message below. So force it.
    begin
      STDERR.puts $!.message 
      STDERR.puts $!.backtrace[0]
    rescue
    end
  end
  STDERR.print "Press ENTER to close the window..."
  STDERR.flush
  STDIN.getc
}
