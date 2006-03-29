# A small piece of code to prepare the script
# for 'script running' from FreeRIDE
BEGIN {

  # redirecting STDERR to STDOUT to keep output 
  # synchronized on the FreeRIDE side.
  STDERR.reopen(STDOUT)
  $defout.sync = true
  $deferr.sync = true

}

# make sure that the Exception message
# appears at the beginning of a line
END {
  unless $!.kind_of? SystemExit
    STDERR.print "\n"
    STDERR.flush
  end
}
