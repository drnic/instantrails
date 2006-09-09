# Purpose: 
#
# $Id: basic_source_parser.rb,v 1.2 2005/10/21 11:23:26 jonathanm Exp $
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
require 'rubyide_tools_source_parser/basic_parser'

module FreeRIDE
  module Tools
    
    ##
    # This creates a parser for an editpane.  Its function (to parse the source) is
    # available by calling editpane.manager.parse_text
    #
    class SourceParser
      extend FreeBASE::StandardPlugin
      
      def SourceParser.start(plugin)
        plugin["/system/ui/components/EditPane"].subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent.name == 'EditPane')
            SourceParser.new(plugin, slot)
          end
        end
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin, slot)
        @slot = slot
        @plugin = plugin
        @parser = BasicRubyParser.new
        @slot['actions/parse_code'].set_proc method(:parse_code)
      end
      
      def parse_code(text)
        return nil unless text
        begin
          root = @parser.parse(text)
        rescue
          root = nil
        end
        root
      end
    end
    
  end
end
