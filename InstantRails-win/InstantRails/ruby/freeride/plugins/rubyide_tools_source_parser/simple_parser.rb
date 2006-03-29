# Purpose: 
#
# $Id: simple_parser.rb,v 1.5 2005/12/08 11:29:19 jonathanm Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2003 Rich Kilmer. All rights reserved.
#
module FreeRIDE

  module Tools
  
    # from snapshot.rb
    class SnapshotFile
      
      def initialize( file_obj )
        @f = file_obj
        @ripper = nil
        @lines = []
        @total_char_sz = 0
        @num_ws_lines = 0  # Number of whitespace lines
      end
      
      attr_accessor :ripper, :num_ws_lines
      
      def gets
        s = @f.gets
        @lines.push(s)
        @total_char_sz += s.length unless s.nil?
        @num_ws_lines += 1 if s =~ /^[\s]*$/
        s
      end
      
      def line_no
        @lines.size - 1
      end
      
      def char_no
        @ripper.pointer || @total_char_sz
      end
      
      def extract( p1, p2 )
        beg, fin = [p1, p2].sort
        
        tmp = []
        tmp.push( @lines[beg.line_no][ beg.char_no .. -1 ] )
        (beg.line_no + 1 ... fin.line_no).each do |i|
          tmp.push( @lines[i] )
        end
        tmp.push( @lines[fin.line_no][ 0 ... fin.char_no ] ) if fin.line_no > beg.line_no
        
        tmp.join('')
      end
      
      def get_line(line_no)
        @lines[line_no]
      end
      
    end
    
    class Position
      
      include Comparable
      
      def initialize( n, c, i = 0)
        @line_no = n
        @char_no = [c,0].max
        @index = i
      end
      
      attr_reader :line_no, :char_no, :index
      
      def <=>( other )
        if @line_no > other.line_no then
          1
        elsif @line_no < other.line_no then
          -1
        else
          if @char_no > other.char_no then
            1
          elsif @char_no < other.char_no then
            -1
          else
            0
          end
        end
  
      end
    end
    
    class SimpleParser < Ripper
      
      class SimpleStringIO
        def initialize(str, dup = true)
          if dup
            @str = str.dup
          else
            @str = str	
          end
          
          @pos = 0
          @last_index = str.size - 1
        end
              
        def gets
          if @pos >= @last_index
            nil
          else
            if p = @str.index(/\n/, @pos)
              line = @str[@pos..p]
            else
              line = @str[@pos..-1]
            end
            
            @pos += line.size
            line
          end
        end
      end
      
      include SourceStructures
      
      def initialize
        super
        clear
      end
      
      def parse_string(string)
        parse(SimpleStringIO.new(string))
      end
      
      def parse( file_obj, filename = '' , path = '')
        clear
        
        @f = SnapshotFile.new(file_obj)
        @f.ripper = self
        @filename = filename
        @path = path
        
        super(@f)
        @top.end_point = create_point
        @top.num_whitespace = @f.num_ws_lines
        @top.calculate_total_comments
        s = Source.new(filename, path, @top)
        s       
      end
      
      def clear
        @filename = ''
        @path = ''
        @cur_context = TopLevelContext.new
        @top = @cur_context
        @f = nil
      end
      
      def add_method_obj(start)
        str = @f.get_line(start.line_no)[start.char_no..-1]
        
        m = ''
        
        # OK: "def <=>", "def initialize", "def foo(a,b)", "def obj.set"
        # NG: "def obj. set", "def||"
        if /^def\s+([^\n\r;]+(?:\!\?)?)[\s\(\r\n;]/ =~ str 
          m = $1
        end
        
        if str.index('.')
          m = SingletonMethod.new(start, m)
        else
          m = NormalMethod.new(start, m)
        end
        
        @cur_context.add_method(m)
        @cur_context = m
      end
      
      def add_class_obj(start)
        str = @f.get_line(start.line_no)[start.char_no..-1]
        
        #p start; p str
        obj = nil
        if /^class\s+(\w+)(?:\s*<\s*(\w+))?/ =~ str
          c = $1
          super_class = $2
          obj = NormalClass.new(start, c)
          obj.super_class = super_class
        elsif /^class\s*<<\s*(\S+)/ =~ str
          obj = SingletonClass.new(start, $1)
        end
        
        @cur_context.add_class(obj)
        @cur_context = obj
      end
      
      def add_module_obj(start)
        str = @f.get_line(start.line_no)[start.char_no..-1]
        
        #p start; p str
        m = nil
        if /^module\s+(\w+)/ =~ str
          m = $1
        end
        
        obj = NormalModule.new(start, m)
        @cur_context.add_module(obj)
        @cur_context = obj
      end
      
      def create_point(offset = 0)
        Position.new( @f.line_no, (@f.char_no - offset) )
      end
      
      def on__KEYWORD( str, *rest )
        # str == 'def' ? @f.mark(-str.size) : str
        if str == 'def'
          add_method_obj( create_point(3) )
        elsif str == 'class'
          add_class_obj( create_point(5) )
        elsif str == 'module'
          add_module_obj( create_point(6) )
        else
          str
        end
      end
      
      def __go_parent_context
        @cur_context.end_point = create_point      
        @cur_context = @cur_context.parent      
      end
      
      def on__def(*rest)
        __go_parent_context
      end
      
      def on__sdef(*rest)
        __go_parent_context
      end
      
      def on__class(*rest)
        __go_parent_context
      end
      
      def on__sclass(*rest)
        __go_parent_context
      end
      
      def on__module(*rest)
        __go_parent_context
      end
      
      def on__comment(*rest)
        @cur_context.num_comments += 1 
      end
      
    end
  end
end
