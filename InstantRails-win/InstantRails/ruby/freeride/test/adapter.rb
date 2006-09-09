# Purpose: FreeBASE databus adapter test
#    
# $Id: adapter.rb,v 1.4 2002/05/30 15:23:09 ljulliar Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#
# This file is part of the FreeBASE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
# 
# Copyright (c) 2001 Rich Kilmer. All rights reserved.
#

require 'freebase/databus'

db = FreeBASE::DataBus.new

slots = [ db["/FirstName"], db["/MiddleName"], db["/LastName"], db["/FullName"] ]

FreeBASE::DataBus::Adapter.new(slots) do |msg, slot| 
	if slot.name=="FullName"
		slot["/FirstName"].data, slot["/MiddleName"].data, slot["/LastName"].data = slot["/FullName"].data.split
	else
		slot["/FullName"].data = "#{slot['/FirstName'].data} #{slot['/MiddleName'].data} #{slot['/LastName'].data}"
	end
end

db["/"].subscribe {|event, slot| puts "slot: #{slot.path} value: #{slot.data}"} 
#This prints out the commented messages below

db["/FirstName"].data = "Richard"
#slot: /FullName/ value: Richard  
#slot: /FirstName/ value: Richard

db["/MiddleName"].data = "Allen"
#slot: /FullName/ value: Richard Allen 
#slot: /MiddleName/ value: Allen

db["/LastName"].data = "Kilmer"
#slot: /FullName/ value: Richard Allen Kilmer
#slot: /LastName/ value: Kilmer

db["/FullName"].data = "Ingrid Heidi Kilmer"
#slot: /FirstName/ value: Ingrid
#slot: /MiddleName/ value: Hiedi
#slot: /LastName/ value: Kilmer
#slot: /FullName/ value: Ingrid Hiedi Kilmer
