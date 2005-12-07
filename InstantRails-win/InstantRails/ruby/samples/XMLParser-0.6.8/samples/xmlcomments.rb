#! /usr/local/bin/ruby

## Ruby version of xmlcomments
## 1998 by yoshidam
##
## This sample comes from Clark Cooper's sample of  Perl extension
## module XML::Parser.
##   (http://www.netheaven.com/~coopercc/xmlparser/samples/xmlcomments)

require 'xml/parser'

$count = 0

p = XML::Parser.new

def p.character(data)
end

def p.default(data)
  if data =~ /^<!--/
    line = self.line
    data.gsub!(/\n/, "\n\t");
    print "#{line}:\t#{data}\n";
    $count += 1
  end
end

p.parse($<)

print "Found #{$count} comments.\n"
