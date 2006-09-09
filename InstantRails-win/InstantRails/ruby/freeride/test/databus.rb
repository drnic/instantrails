# Purpose: FreeBASE databus test
#    
# $Id: databus.rb,v 1.4 2002/02/06 03:34:24 richkilmer Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
# 
# Copyright (c) 2001 Rich Kilmer. All rights reserved.
#

require 'freebase/databus'

class SubscriptionTest
 def databus_notify(event, slot)
   puts "Tester Class got #{slot.data}"
 end
end

# test data
databus = FreeBASE::DataBus.new
databus["/"].subscribe {|event, slot| puts "data to #{slot.path}"}
st = SubscriptionTest.new
databus["/foo/bar"].subscribe(st)
id = databus["/foo/bar"].subscribe {|event, slot| puts "Block got #{slot.data} event #{event.to_s}" }
databus["/foo/bar"].data = "data :-)" #=> publishes data
databus["/foo/bar"].unsubscribe(id)
databus["/foo/bar"].unsubscribe(st)
databus["/foo/bar/int"].validate_with("Does not implement to_i") { | value | value.respond_to? "to_i" }
begin
 databus["/foo/bar/int"].data = Hash.new  #=> raises Does not implement to_i
rescue
 puts "verified verified_with respond_with.to_i"
end

#test queue
databus["/foo/bar/queue"].queue
databus["/foo/bar/queue"].subscribe {|event, slot| puts "event: #{event.to_s}"}
databus["/foo/bar/queue"].join "first"
databus["/foo/bar/queue"] << "second"
puts databus["/foo/bar/queue"].leave
begin
 databus["/foo/bar/queue"].stack
rescue
 puts "verified that it cannot override to a stack"
end

#test stack
databus["/foo/bar/stack"].stack
databus["/foo/bar/stack"].subscribe do |event, slot|
 puts "Got notification in stack #{event.to_s}"
 if event == :notify_stack_push
   puts "Pop inside of subscriber: #{slot.pop}"
 end
end
databus["/foo/bar/stack"].push "one"
begin
 databus["/foo/bar/queue"].data
rescue
 puts "verified that it cannot override to data slot"
end
begin
 databus["/foo/bar/queue"].data="value"
rescue
 puts "verified that it cannot override to data (=) slot"
end

#test proc
databus["/foo/bar/proc"].set_proc {|p1, p2| puts "Got #{p1} and #{p2}"}
databus["/foo/bar/proc"].validate_with("Must have two args") {|args| args.size==2}
databus["/foo/bar/proc"].subscribe {|event, slot| puts "event: #{event.to_s}"}
databus["/foo/bar/proc"].call("one", "two")
begin
 databus["/foo/bar/proc"].call("one", "two", "three")
rescue
 puts "verified that proc args check works"
end

#Test traversal
slot = databus["/foo/bar/proc"]
puts slot.path
puts slot[".."].path
puts slot["../stack"].path
puts slot[".././stack"].path
puts slot["/foo/bar/queue"].path 
puts slot["././."].path
puts slot["/foo/bar///queue"].path 
puts slot["///foo///bar///queue"].path 

slot["test"].attr_foo = "foo"
puts slot["test"].attr_foo
