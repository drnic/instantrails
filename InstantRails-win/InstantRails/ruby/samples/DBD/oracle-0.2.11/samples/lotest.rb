#! /usr/local/bin/ruby

## insertion/retrieval test for Large Object

require 'oracle'

lo = nil
open(ARGV[0]) do |f|
  lo = f.read
end

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
conn.exec("create table test (a integer, b long raw)")
conn.exec("insert into test values (1, :0)", Oracle::Binary(lo))
c = conn.exec("select * from test")
p c.getColNames
c.fetch do |v|
  p [v[0], v[1].size]
end
c.close
conn.exec("drop table test")
conn.commit
conn.logoff
