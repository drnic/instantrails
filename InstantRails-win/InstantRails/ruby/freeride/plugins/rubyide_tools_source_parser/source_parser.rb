# Purpose: Plugin to create parsers for Editpanes.
#
# $Id: source_parser.rb,v 1.4 2006/02/26 14:25:19 jonathanm Exp $
#
# Authors:  Rich Kilmer <rich@infoether.com>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2003 Rich Kilmer. All rights reserved.
# Modified 2005 by Jonathan Maasland <nochoice @ xs4all.nl>

require 'ripper.rb'
require 'rubyide_tools_source_parser/source_structures'
require 'rubyide_tools_source_parser/simple_parser'

module FreeRIDE
  module Tools
    
    ##
    # This creates a parser for an editpane.  Its function (to parse the source) is
    # available by calling editpane.manager.parse_code
    #
    class SourceParser
      extend FreeBASE::StandardPlugin
      
      def SourceParser.start(plugin)
        @@lastParserIdx = 1
        # Create a SourceParser for each editPane created
        plugin["/system/ui/components/EditPane"].subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent.name == 'EditPane')
            SourceParser.new(plugin, slot)
          end
        end
        # Create a SourceParser to be used for parsing unopened files
        unbound_parser = plugin['/system/tools/SourceParser/unbound']
        unbound_parser.data = SourceParser.new(@plugin, unbound_parser)
        
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, slot)
        @slot = slot
        @plugin = plugin
        @parser = SimpleParser.new
        @slot['actions/parse_code'].set_proc method(:parse_code)
        @slot["/system/tools/SourceParser/#{@@lastParserIdx}"].data = self
        @@lastParserIdx += 1
        @source_cache = {}
      end
      
      def parse_code(text)
        return nil unless text
        begin
          source = @parser.parse_string(text)
        rescue
          source = nil
        ensure
          @parser.clear
        end
        source
      end
      
      # Parses file_obj and returns it's source structure
      # If filename and path are given then the source-struct will be cached
      # The modification time of the file is used to determine if the cached parsed structure is up to date
      def parse(file_obj, filename='', path='')
        return nil unless file_obj
        
        source = get_cached_source(file_obj, filename, path)
        return source unless source.nil?
        begin
          source = @parser.parse(file_obj, filename, path)
          cache_source(filename, path, source)
        rescue
          #puts "Exception after parsing", $!.message, $!.backtrace.join("\n")
          #puts "Parsing failed for file #{File.join(path,filename)}"
          source = nil
        ensure
          @parser.clear
        end
        source
      end
      
      # Returns the cached source-structure if it exists and isn't out of date.
      # nil is returned otherwise
      def get_cached_source(file_obj, filename, path)
        return nil if filename=='' or path==''
        f = File.join(path, filename)
        if @source_cache.has_key?(f) and @source_cache[f].up2_date?
          return @source_cache[f].source
        end
        
        nil
      end
      
      def cache_source(filename, path, source)
        return if filename == '' or path == ''
        f = File.join(path, filename)
        @source_cache[f] = CacheStructure.new(filename, path, source)
      end
      
      class CacheStructure
        attr_accessor :filename, :path, :cache_atime, :source
        
        def initialize(fn, path, src)
          @filename = fn
          @path = path
          @source = src
          @f = File.join(path,fn)
          @cache_mtime = File.mtime(@f)
          yield(self) if block_given?
        end
        
        def up2_date?()
          return @cache_mtime == File.mtime(@f)
        end
        
      end
      
    end # of class SourceParser
    
  end
end
