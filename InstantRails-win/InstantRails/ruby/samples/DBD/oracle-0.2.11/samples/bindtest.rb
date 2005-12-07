#! /usr/local/bin/ruby

require 'oracle'

conn = ORAconn.logon("scott", "tiger", "parsifal")
#conn = ORAconn.logon("scott", "tiger", "boston")
cursor = conn.open
cursor.parse("select * from emp where job=:a")
cursor.bindrv(":a", "CLERK")
cursor.exec
while r = cursor.fetch
  p r
end
cursor.close
conn.logoff
