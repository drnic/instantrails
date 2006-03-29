# Purpose: Setup and initialize the core gui interfaces
#
# $Id: key_manager.rb,v 1.1.1.1 2002/12/20 17:27:31 richkilmer Exp $
#
# Authors:  Curt Hibbs <curt@hibbs.com>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2001 Curt Hibbs. All rights reserved.
#

module FreeRIDE

  module Commands

    class KeyManager
      extend FreeBASE::StandardPlugin
      
      def KeyManager.start(plugin)
        KeyManager.new(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      def initialize(plugin)
        @plugin = plugin
        @cmd_base = @plugin["/system/ui/keys"]
        @cmd_base.manager = self
      end
      
      def bind(command, *keylist)
        @cmd_base[get_path(keylist)].data = command
      end
      
      def unbind(*keylist)
        @cmd_base[get_path(keylist)].data = nil
      end
      
      def get_binding(command)
        keylist = nil
        @cmd_base.each_slot(true) do |slot|
          if slot.data == command
            path = slot.path
            keylist = []
            keylist << :ctrl if path.include? '/Ctrl'
            keylist << :shift if path.include? '/Shift'
            keylist << :alt if path.include? '/Alt'
            keylist << slot.name.intern
            break
          end
        end
        return keylist
      end
      
      def get_path(keylist)
        path = ""
        path += "Ctrl/" if keylist.delete(:ctrl)
        path += "Shift/" if keylist.delete(:shift)
        path += "Alt/" if keylist.delete(:alt)
        path += keylist.first.to_s.upcase
      end
      
    end

  end
end