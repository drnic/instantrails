# FreeRIDE Ruby Integrated Development Environment
#
# $Id: style.rb,v 1.1 2004/09/13 21:28:46 ljulliar Exp $
#
# Authors: Rich Kilmer, Laurent Julliard
# Contributors: 
#
# Copyright (c) 2001, Richard Kilmer, rich@infoether.com
# Licensed under the Ruby License

require "rubyide_fox_gui/fxscintilla/colour"
require "rubyide_fox_gui/fxscintilla/scintilla_wrapper"

module Scintilla


  class Style

    ITALIC = 1
    BOLD = 2
    UNDERLINE = 4
    EOLFILLED = 8
    FONT = 16
    FORE = 32
    BACK = 64
    SIZE = 128
    CASE_FORCE = 256
    CHARACTER_SET = 512

    attr_reader :characterSet, :specified, :store, :name, :description

    def initialize(str="", name=nil, description=nil)
      @specified=0
      @name = name
      @description = description
      @store = EmptyStyleStore.new
      str.split(",").each do |token|
	if token[0,6]=="italic"
	  @italic=true
	  @specified = @specified | ITALIC
	elsif token[0,9]=="notitalic"
	  @italic=false
	  @specified = @specified | ITALIC
	elsif token[0,4]=="bold"
	  @bold=true
	  @specified = @specified | BOLD
	elsif token[0,7]=="notbold"
	  @bold=false
	  @specified = @specified | BOLD
	elsif token[0,9]=="eolfilled"
	  @eolfilled=true
	  @specified = @specified | EOLFILLED
	elsif token[0,12]=="noteolfilled"
	  @eolfilled=false
	  @specified = @specified | EOLFILLED
	elsif token[0,9]=="underline"
	  @underline=true
	  @specified = @specified | UNDERLINE
	elsif token[0,12]=="notunderline"
	  @underline=false
	  @specified = @specified | UNDERLINE
	elsif token[0,4]=="fore"
	  @fore=Colour.new(token[5,7])
	  @specified = @specified | FORE
	elsif token[0,4]=="back"
	  @back=Colour.new(token[5,7])
	  @specified = @specified | BACK
	elsif token[0,4]=="size"
	  @size=token[5..-1].to_i
	  @specified = @specified | SIZE
	elsif token[0,4]=="font"
	  @font=token[5..-1]
	  @specified = @specified | FONT
	elsif token[0,4]=="case"
	  @caseForce = SC_CASE_UPPER if token[5,1]=="u"
	  @caseForce = SC_CASE_LOWER if token[5,1]=="l"
	  @caseForce = SC_CASE_MIXED if token[5,1]=="m"
	  @specified = @specified | CASE_FORCE
	end
      end

    end

    def store=(style_store)
      @store = style_store
    end
    
    def +(style)
      return Style.new(self.text+","+style.text)
    end

    def bold?
      @bold.nil? ? @store.default_style.bold? : @bold
    end
    
    def bold=(status)
      case status
	when nil
	@specified = @specified & ~BOLD
	when true
	@specified = @specified | BOLD
	@bold = true
	when false
	@specified = @specified | BOLD
	@bold = false
      end
    end

    def italic?
      @italic.nil? ? @store.default_style.italic? : @italic
    end

    def italic=(status)
      case status
	when nil
	@specified = @specified & ~ITALIC
	when true
	@specified = @specified | ITALIC
	@italic = true
	when false
	@specified = @specified | ITALIC
	@italic = false
      end
    end

    def underline?
      @underline.nil? ? @store.default_style.underline? : @underline
    end

    def underline=(status)
      case status
	when nil
	@specified = @specified & ~UNDERLINE
	when true
	@specified = @specified | UNDERLINE
	@underline = true
	when false
	@specified = @specified | UNDERLINE
	@underline = false
      end
    end

    def eolfilled?
      @eolfilled.nil? ? @store.default_style.eolfilled? : @eolfilled
    end

    def eolfilled=(status)
      case status
	when nil
	@specified = @specified & ~EOLFILLED
	when true
	@specified = @specified | EOLFILLED
	@eolfilled = true
	when false
	@specified = @specified | EOLFILLED
	@eolfilled = false
      end
    end

    def fore
      @fore || @store.default_style.fore
    end

    def fore=(rgb_string)
      if rgb_string
	@specified = @specified | FORE
	@fore = rgb_string
      else
	@specified = @specified & ~FORE
	@fore = nil
      end
    end

    def back
      @back || @store.default_style.back
    end

    def back=(rgb_string)
      if rgb_string
	@specified = @specified | BACK
	@back = rgb_string
      else
	@specified = @specified & ~BACK
	@back = nil
      end
    end

    def font
      @font || @store.default_style.font
    end

    def font=(font)
      if font
	@specified = @specified | FONT
	@font = font
      else
	@specified = @specified & ~FONT
	@font = nil
      end
    end

    def size
      @size || @store.default_style.size
    end

    def size=(size)
      if size
	@specified = @specified | SIZE
	@size = size
      else
	@specified = @specified & ~SIZE
	@size = nil
      end
    end

    def to_s
      elts = []
      elts << 'italic' if (@specified & ITALIC)!=0 && @italic
      elts << 'notitalic' if (@specified & ITALIC)!=0 && !@italic
      elts << 'bold' if (@specified & BOLD)!=0 && @bold
      elts << 'notbold' if (@specified & BOLD)!=0 && !@bold
      elts << 'eolfilled' if (@specified & EOLFILLED)!=0 && @eolfilled
      elts << 'noteolfilled' if (@specified & EOLFILLED)!=0 && !@eolfilled
      elts << 'underline' if (@specified & UNDERLINE)!=0 && @underline
      elts << 'notunderline' if (@specified & UNDERLINE)!=0 && !@underline
      elts << "fore:#{@fore.to_s}" if (@specified & FORE)!=0
      elts << "back:#{@back.to_s}" if (@specified & BACK)!=0
      elts << "size:#{@size}" if (@specified & SIZE)!=0
      elts << "font:#{@font}" if (@specified & FONT)!=0
      elts << "caseu" if (@specified & CASE_FORCE)!=0 && (@caseForce == SC_CASE_UPPER)
      elts << "casel" if (@specified & CASE_FORCE)!=0 && (@caseForce == SC_CASE_LOWER)
      elts << "casem" if (@specified & CASE_FORCE)!=0 && (@caseForce == SC_CASE_MIXED)
      elts.join(',')
    end
    alias_method :text, :to_s

  end

  class EmptyStyle
    # all accessors to this style returns nil meaning everything is unspecified
    def method_missing(methId)
      nil
    end
  end



  class EmptyStyleStore
    attr_reader :default_style
    def initialize()
      @default_style = EmptyStyle.new
    end
  end

  class StyleStore

    attr_reader :name, :default_style

    if RUBY_PLATFORM =~ /(mswin32|mingw32)/
      default_size = 10
    else
      default_size = 12
    end
    BASE_STYLE = Style.new("back:#FFFFFF,fore:#000000,noteolfilled,notbold,notitalic,notunderline,casem,font:courier,size:#{default_size}")

    def initialize(name)
      @name = name
      @store = Hash.new
      self.default_style = BASE_STYLE
    end
    
    def clear_all_styles
      @store.each_key { |style_name| @store[style_name] = Style.new("") }
      self.default_style = BASE_STYLE
    end

    def default_style=(style)
      @default_style = @store['DEFAULT'] = style
    end

    def []=(style_name, style)
      style.store = self
      @store[style_name] = style
    end

    def [](style_name)
      @store[style_name]
    end

    def each(&block)
      return unless block_given?
      @store.each_value { |style| yield style }
    end

    def remove(style_name)
      style.store = nil
      @store.delete(style_name)
    end

  end

end


# Test script
if $0 == __FILE__

  require 'runit/testcase'
  require 'runit/cui/testrunner'

  class TestStyle < RUNIT::TestCase

    include Scintilla

    def test_all
      s1 = Style.new("font:helvetica,size:14")
      assert_equals(s1.text,"size:14,font:helvetica")
      assert_equals(s1.bold?, nil)
      assert_equals(s1.font, "helvetica")
      assert_equals(s1.back, nil)

      s2 = Style.new("back:#E8E8F8,fore:#7070C0,size:18")
      assert_equals(s2.back.to_s, "#E8E8F8")

      s3 = s1 + s2
      assert_equals(s3.font,"helvetica")
      assert_equals(s3.size,18)
      assert_equals(s3.back.to_s,"#E8E8F8")
      assert_equals(s3.fore.to_s,"#7070C0")

      ss = StyleStore.new('RubyStyles')
      ss['MY_STYLE']=s1
      assert_equals(s1.size,14)
      assert_equals(s1.font, "helvetica")
      assert_equals(s1.bold?, ss.default_style.bold?)
      assert_equals(s1.fore.to_s, ss.default_style.fore.to_s)

    end

  end

end
