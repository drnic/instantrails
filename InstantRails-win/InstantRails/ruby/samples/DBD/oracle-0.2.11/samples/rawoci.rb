#! /usr/local/bin/ruby

require 'oracle'

conn = ORAconn.logon("yoshidam", "yoshidam", "")
cursor = conn.open
cursor.parse("select ROWID, A from test3")
i = 1
while ret = cursor.describe(i)
  if ret[1] == 2
    cursor.define(i, 0, 4);
  else
    cursor.define(i, ret[3], 1);
  end
  p ret
  i += 1
end
p cursor.exec
while r = cursor.fetch
  i = 1
  p cursor.getROWID
  while row = cursor.getCol(i)
    p row
    i += 1
  end
end
cursor.close
#c = conn.open
#c.parse("insert into test values (123, 'hoge')")
#p c.exec
#p c.getROWID
#conn.rollback
conn.logoff
