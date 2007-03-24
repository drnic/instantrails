#! /usr/local/bin/ruby

## Ruby version of xmlstats
## 1999 by yoshidam
##
## This sample comes from Clark Cooper's sample of Perl extension
## module XML::Parser.
##   (http://www.netheaven.com/~coopercc/xmlparser/samples/xmlstats)
##
## Try XML benchmark (http://www.xml.com/xml/pub/Benchmark/article.html)!
## Ruby is probably faster than Perl.

require 'xml/parser'
begin
  require 'mbstring'
rescue LoadError
  class String
    def mblength
      cnt = self.length
      self.scan(/([\300-\367])/n) do |c|
        if c[0] < "\340"
          cnt -= 1
        elsif c[0] < "\360"
          cnt -= 2
        else
          cnt -= 3
        end
      end
      cnt
    end
  end
end

$KCODE="UTF8"

class Elinfo
  attr :name
  attr :count, true
  attr :minlev, true
  attr :seen, true
  attr :chars, true
  attr :empty, true
  attr :ptab, true
  attr :ktab, true
  attr :atab, true

  def initialize(name, seen)
    @name = name
    @count = 0
    @minlev = nil
    @seen = seen
    @chars = 0
    @empty = true
    @ptab = {}
    @ptab.default = 0
    @ktab = {}
    @ktab.default = 0
    @atab = {}
    @atab.default = 0
  end

  def <=>(b)
    ret = self.minlev - b.minlev
    if ret == 0
      return self.seen - b.seen
    end
    ret
  end
end

class StatParser < XML::Parser
  def initialize(*rest)
    @elements = {}
    @seen = 0
    @root = nil
    @context = []
  end

  def startElement(name, attr)
    if (elinf = @elements[name]).nil?
      @elements[name] = elinf = Elinfo.new(name, @seen += 1)
    end
    elinf.count += 1

    pinf = @context[-1]
    if pinf
      elinf.ptab[pinf.name] += 1
      pinf.ktab[name] += 1
      pinf.empty = false
    else
      @root = name
    end

    attr.each_key do |key|
      elinf.atab[key] += 1
    end
    @context.push(elinf)
  end

  def endElement(name)
    @context.pop
  end

  def character(data)
    inf = @context[-1]
    inf.empty = false
    inf.chars += data.mblength
  end

  def set_minlev(name, level)
    name = @root if name.nil?
    inf = @elements[name]
    if inf.minlev.nil? or inf.minlev > level
      newlev = level + 1
      inf.minlev = level
      inf.ktab.each_key do |key|
        set_minlev(key, newlev)
      end
    end
  end

  def elinf_sort
    @elements.sort { |(a_name, a_inf), (b_name, b_inf)|
      a_inf <=> b_inf
    }.each do |name, inf|
      yield(name, inf)
    end
  end
end

def showtab(label, tab, dosum)
  if tab.length == 0; return end
  print "\n   ", label, ":\n"
  sum = 0

  tab.sort.each do |name, cnt|
    sum = sum + cnt
    printf("      %-16s      %5d\n", name, cnt)
  end
  if dosum and tab.length > 1
    print "                            =====\n"
    printf("                            %5d\n", sum);
  end
end

p = StatParser.new
begin
  p.parse($<.read)
rescue XML::ParserError
  print "#{$0}: #{$!} (in line #{p.line})\n"
  exit 1
end

p.set_minlev(nil, 0)
p.elinf_sort do |name, elinf|
  print "\n================\n"
  print name, ": ", elinf.count, "\n"
  if elinf.chars > 0
    print "Had ", elinf.chars, " bytes of character data\n"
  end
  if elinf.empty
    print "Always empty\n"
  end
  showtab("Parents", elinf.ptab, false)
  showtab("Children", elinf.ktab, true)
  showtab("Attributes", elinf.atab, false)
end
