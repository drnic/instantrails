#! /usr/local/bin/ruby

require 'oracle'

#conn = Oracle.new("scott", "tiger", "")
conn = Oracle.new("yoshidam", "yoshidam", "")
begin
  conn.exec("drop table test")
  print "table test droped\n"
rescue OCIError
  if $!.to_s !~ /^ORA-00942/
    print "Error: #{$!}\n"
    exit 1
  end
end
conn.exec("create table test (a integer)")
conn.exec("insert into test values (1)")
c = conn.exec("select * from test")
p c.getColNames
c.fetch do |v|
  p v
end
c.close
conn.exec("drop table test")
conn.commit
conn.logoff
