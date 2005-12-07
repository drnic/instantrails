#! /usr/local/bin/ruby

## Oracle module for Ruby sample
## 1998 by yoshidam

require 'oracle'
require 'parsearg'
require 'readline'
include Readline

Readline.completion_proc = proc {|str|
  case str
  when "a", "al", "alt", "alte", "alter"
    ["alter"]
  when "c", "cr", "cre", "crea", "creat", "create"
    ["create"]
  when "d"
    ["delete", "drop"]
  when "de", "del", "dele", "delet", "delete"
    ["delete"]
  when "dr", "dro", "drop"
    [ "drop" ]
  when "f", "fr", "fro", "from"
    ["from"]
  when "i", "in"
    ["insert", "into"]
  when "int"
    ["into"]
  when "ins", "inse", "inser", "insert"
    ["insert"]
  when "l", "li", "lik", "like"
    ["like"]
  when "s","se"
    ["select", "set"]
  when "sel","sele","selec", "select"
    ["select"]
  when "set"
    ["set"]
  when "t", "ta", "tab", "tabl", "table"
    ["table"]
  when "u", "up", "upd", "upda", "updat", "update"
    ["update"]
  when "w", "wh", "whe", "wher", "where"
    ["where"]
  end
}

parseArgs(0, nil, "h", "L:")
if $OPT_h
  print "Usage: #{$0} [-L user[/password][@dbname]]\n"
  exit 0
end
if $OPT_L.nil?
  $OPT_L = ENV["USER"] || ENV["LOGNAME"]
end

begin
  conn = Oracle.new($OPT_L, nil, nil)
rescue OCIError
  print "SQL Error: #{$!}\n"
  exit 1
end

while true
  line = readline("ORACLE> ", true)
  break if line.nil? || line == ''
  line.chop! if line[-1] == ?;
  begin
    cursor = conn.exec(line)
  rescue OCIError
    print "SQL Error: #{$!}\n"
    next
  end
  names = cursor.getColNames
  if names.length > 0
    w = cursor.getDWidth
    len = 0
    names.each_with_index do |n, i|
      print format("%.*s|", w[i] -1, n)
      len += w[i]
    end
#    print names.join('|') + "\n"
    print "\n" + "-" * len + "\n"
    cursor.fetch do |row|
      print row.join('|') + "\n"
    end
  end
  cursor.close
end


conn.logoff
