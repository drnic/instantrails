$:.unshift Dir.pwd
require 'eventlog'

include Win32

EventLog.open('System').tail{ |log|
   p log
}
