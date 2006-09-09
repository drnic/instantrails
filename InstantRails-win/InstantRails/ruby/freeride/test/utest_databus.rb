# Purpose: FreeBASE databus unit test
#    
# $Id: utest_databus.rb,v 1.11 2002/11/19 04:10:54 richkilmer Exp $
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

require 'rubyunit'
require 'freebase/databus'

class Test_DataBus < TestCase
	
  def test_1_subscribe
    bus = FreeBASE::DataBus.new
    parentNotified = slotNotified = false
    bus["/"].subscribe do |event, slot| 
      if event == :notify_data_set
        assert_equal("/foo/bar/", slot.path, "Parent was not notified of corrent slot")
        assert_equal("test", slot.data, "Parent was not notified with correct data")
        parentNotified = true
      end
    end
    id = bus["/foo/bar"].subscribe do |event, slot| 
      if event == :notify_data_set
        assert_equal("test", slot.data, "Slot was not notified with correct data")
        slotNotified = true
      end
    end
    bus["/foo/bar"].data = "test"
    assert_equal("test", bus["/foo/bar"].data, "Value was not set correctly")
    assert(parentNotified, "Parent of /foo/bar was not notifed")
    assert(slotNotified, "Slot /foo/bar was not notified")
    bus["/foo/bar"].unsubscribe(id)
    slotNotified = parentNotified = false
    bus["/foo/bar"].data = "test"
    assert_equal("test", bus["/foo/bar"].data, "Value was not set correctly")
    assert(!slotNotified, "Slot unsubscribed but was notified anyway")
    assert(parentNotified, "Parent is still subscribed but was not notified")
    bus["/foo/bar"].propagate_notifications=false
    parentNotified = false
    bus["/foo/bar"].data = "test"
    assert_equal("test", bus["/foo/bar"].data, "Value was not set correctly")
    assert(!parentNotified, "Propagation of notifications was suspended but was notifed anyway")
    #TODO:  nofications for other types of slots and slot creation events
  end

  def test_2_validate
    bus = FreeBASE::DataBus.new
    bus["/foo/bar/int"].validate_with("Does not implement to_i") { | value | value.respond_to? "to_i" }
    bus["/foo/bar/int"].data = 1
    assert_equal(1, bus["/foo/bar/int"].data)
    assert_exception(RuntimeError) {bus["/foo/bar/int"].data = Hash.new}
  end
  
  def test_3_slottype_data
    bus = FreeBASE::DataBus.new
    slot = bus["slot"]
    slot.data = 1
    assert(slot.is_data_slot?)
    assert(!slot.is_queue_slot?)
    assert(!slot.is_stack_slot?)
    assert(!slot.is_proc_slot?)
    assert(!slot.is_map_slot?)
    assert_equal(1, slot.data)
    assert_equal(1, slot.value)
    assert_exception(RuntimeError) {slot.proc}
    assert_exception(RuntimeError) {slot.queue}
    assert_exception(RuntimeError) {slot.stack}
    assert_exception(RuntimeError) {slot.map}
    assert_exception(RuntimeError) {slot.set_proc {|param| return param} }
    assert_exception(RuntimeError) {slot.call(2) }
    assert_exception(RuntimeError) {slot << 1}
    assert_exception(RuntimeError) {slot.join(1)}
    assert_exception(RuntimeError) {slot.leave}
    assert_exception(RuntimeError) {slot.push(1)}
    assert_exception(RuntimeError) {slot.pop}
    assert_exception(RuntimeError) {slot.put(1,2)}
    assert_exception(RuntimeError) {slot.get(1)}
  end
  
  def test_4_slottype_queue
    bus = FreeBASE::DataBus.new
    slot = bus["slot"]
    slot << 1
    assert(slot.is_queue_slot?)
    assert(!slot.is_data_slot?)
    assert(!slot.is_stack_slot?)
    assert(!slot.is_proc_slot?)
    assert(!slot.is_map_slot?)
    slot.join(2)
    assert_equal(2, slot.count)
    assert_equal(1, slot.leave)
    assert_equal(2, slot.leave)
    assert_equal(0, slot.count)
    assert_exception(RuntimeError) {slot.proc}
    assert_exception(RuntimeError) {slot.data}
    assert_exception(RuntimeError) {slot.stack}
    assert_exception(RuntimeError) {slot.map}
    assert_exception(RuntimeError) {slot.call(2) }
    assert_exception(RuntimeError) {slot.set_proc {|param| return param} }
    assert_exception(RuntimeError) {slot.push(1)}
    assert_exception(RuntimeError) {slot.pop}
    assert_exception(RuntimeError) {slot.put(1,2)}
    assert_exception(RuntimeError) {slot.get(1)}
  end
  
  def test_5_slottype_stack
    bus = FreeBASE::DataBus.new
    slot = bus["slot"]
    slot.push 1
    assert(slot.is_stack_slot?)
    assert(!slot.is_queue_slot?)
    assert(!slot.is_data_slot?)
    assert(!slot.is_proc_slot?)
    assert(!slot.is_map_slot?)
    slot.push 2
    assert_equal(2, slot.count)
    assert_equal(2, slot.pop)
    assert_equal(1, slot.pop)
    assert_equal(0, slot.count)
    assert_exception(RuntimeError) {slot.proc}
    assert_exception(RuntimeError) {slot.data}
    assert_exception(RuntimeError) {slot.queue}
    assert_exception(RuntimeError) {slot.map}
    assert_exception(RuntimeError) {slot.set_proc {|param| return param} }
    assert_exception(RuntimeError) {slot.call(2) }
    assert_exception(RuntimeError) {slot << 1}
    assert_exception(RuntimeError) {slot.join(1)}
    assert_exception(RuntimeError) {slot.leave}
    assert_exception(RuntimeError) {slot.put(1,2)}
    assert_exception(RuntimeError) {slot.get(1)}
  end
  
  def test_6_slottype_proc
    bus = FreeBASE::DataBus.new
    slot = bus["slot"]
    slot.set_proc { |param| assert_equals(4, param) }
    assert(slot.is_proc_slot?)
    assert(!slot.is_stack_slot?)
    assert(!slot.is_queue_slot?)
    assert(!slot.is_data_slot?)
    assert(!slot.is_map_slot?)
    slot.call(4)
    slot.invoke(4)
    slot.proc.call(4)
    assert_exception(RuntimeError) {slot.stack}
    assert_exception(RuntimeError) {slot.data}
    assert_exception(RuntimeError) {slot.queue}
    assert_exception(RuntimeError) {slot.map}
    assert_exception(RuntimeError) {slot << 1}
    assert_exception(RuntimeError) {slot.join(1)}
    assert_exception(RuntimeError) {slot.leave}
    assert_exception(RuntimeError) {slot.push(1)}
    assert_exception(RuntimeError) {slot.pop}
    assert_exception(RuntimeError) {slot.put(1,2)}
    assert_exception(RuntimeError) {slot.get(1)}
  end
  
  def test_7_slottype_map
    bus = FreeBASE::DataBus.new
    slot = bus["slot"]
    slot.put(1,2)
    assert(slot.is_map_slot?)
    assert(!slot.is_stack_slot?)
    assert(!slot.is_queue_slot?)
    assert(!slot.is_data_slot?)
    assert(!slot.is_proc_slot?)
    assert_equal(2, slot.get(1))
    assert_equal(1, slot.count)
    slot.clear
    assert_equal(0, slot.count)
    slot.map.map= {1=>2, 2=>3}
    assert_equal(2, slot.get(1))
    assert_equal(3, slot.get(2))
    assert_exception(RuntimeError) {slot.proc}
    assert_exception(RuntimeError) {slot.stack}
    assert_exception(RuntimeError) {slot.data}
    assert_exception(RuntimeError) {slot.queue}
    assert_exception(RuntimeError) {slot << 1}
    assert_exception(RuntimeError) {slot.join(1)}
    assert_exception(RuntimeError) {slot.leave}
    assert_exception(RuntimeError) {slot.push(1)}
    assert_exception(RuntimeError) {slot.pop}
    assert_exception(RuntimeError) {slot.call(2) }
    assert_exception(RuntimeError) {slot.set_proc {|param| return param} }
  end
  
  def test_8_slot_attributes
    bus = FreeBASE::DataBus.new
    slot = bus["test/slot"]
    slot.attr_test=1
    slot.attr_test2=2
    assert_equal(1, slot.attr_test)
    assert_equal(2, slot.attr_test2)
    assert_nil(slot.attr_test3)
    assert_exception(RuntimeError) {slot.attr_parent=nil}
    assert_exception(RuntimeError) {slot.attr_name=nil}
    assert_exception(RuntimeError) {slot.attr_path=nil}
    assert_equal("slot", slot.attr_name)
    assert_equal(slot.name, slot.attr_name)
    assert_equal("test", slot.attr_parent.name)
    assert_equal(slot.parent.name, slot.attr_parent.name)
    assert_equal("/test/slot/", slot.attr_path)
    assert_equal(slot.path, slot.attr_path)
  end
  
  def test_9_slot_links
    bus = FreeBASE::DataBus.new
    parent = bus["parent"]
    notify_link = false
    
    bus['parent'].subscribe do |event, slot|
      notify_link = true if link = :notify_slot_link 
    end
    child = parent.link("child", "/parent2/child2")
    assert_equal('/parent/child/', bus["/parent/child"].path)
    assert_equal('/parent2/child2/subslot/', bus["/parent/child/subslot"].path)
    assert(parent['child'].is_link_slot?)
    assert(notify_link)
    parent['child'].unlink
    assert_equal('/parent/child/subslot/', bus["/parent/child/subslot"].path)
    assert(!parent['child'].is_link_slot?)
  end
  
end
