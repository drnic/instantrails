#! /usr/local/bin/ruby

## Cursor sample by Clemens Hintze <c.hintze@gmx.net>

require 'oracle'

dbh = Oracle.new("scott", "tiger")
cursor = dbh.parse <<-ESQL
select * 
  from CAT
where TABLE_NAME like :0
ESQL

cursor.exec 'A%'        # Fetch all tables beginning with 'A'
cursor.fetch do |table_name, table_type|
  puts table_name, table_type
end

cursor.close
