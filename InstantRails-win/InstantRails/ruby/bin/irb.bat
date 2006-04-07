@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -Sx "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
"%~d0%~p0ruby" -x "%~f0" %*
goto endofruby
#!/bin/ruby
#
#   irb.rb - intaractive ruby
#   	$Release Version: 0.9.5 $
#   	$Revision: 1.2.2.1 $
#   	$Date: 2005/04/19 19:24:56 $
#   	by Keiju ISHITSUKA(keiju@ruby-lang.org)
#

require "irb"

if __FILE__ == $0
  IRB.start(__FILE__)
else
  # check -e option
  if /^-e$/ =~ $0
    IRB.start(__FILE__)
  else
    IRB.setup(__FILE__)
  end
end

__END__
:endofruby
