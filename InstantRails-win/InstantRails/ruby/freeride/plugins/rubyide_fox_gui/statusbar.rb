# Purpose: Setup and initialize the status bar GUI interface
#
# $Id: statusbar.rb,v 1.5 2005/02/20 08:04:01 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus DOT org
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2003 Laurent Julliard. All rights reserved.
#

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end
require 'fox12/colors'

module FreeRIDE
  module FoxRenderer
    
    ##
    # This is the module that renders Status Bars using
    # FOX.
    #
    class StatusBar
      extend FreeBASE::StandardPlugin
      
      def StatusBar.start(plugin)
        
        component_slot = plugin["/system/ui/components/StatusBar"]
        
        component_slot.subscribe do |event, slot|
          if (event == :notify_slot_add && slot.parent == component_slot)
            Renderer.new(plugin, slot)
          end
        end
        
        component_slot.each_slot { |slot| slot.notify(:notify_slot_add) }
        
        # Now only is this plugin running
        plugin.transition(FreeBASE::RUNNING)
      end
    end
      
      
    ##
    # Each instance of this class is responsible for rendering 
    # a status bar component. There is actually only one for now
    #
    class Renderer
      include Fox
      attr_reader :plugin
      
      def initialize(plugin, slot)
	@plugin = plugin
	@slot = slot
	@plugin.log_info << "Status Bar  #{@slot.name} started"
	
	# Currently we only allow one status bar
	@status_bar = @plugin["/system/ui/fox/FXStatusBar"].data
	@status_line = @status_bar.getStatusLine
	@default_color = @status_line.getTextColor
	@info_color = @default_color
	@warning_color = FXColor::DarkOrange
	@error_color = FXColor::Red
	
	setup_actions
      end
      
      def setup_actions
	# prompt is a short alias to prompt_info
	bind_action("prompt", :prompt_info)
	bind_action("prompt_info", :prompt_info)
	bind_action("prompt_warning", :prompt_warning)
	bind_action("prompt_error", :prompt_error)
	bind_action("clear", :clear)
      end
      
      def bind_action(name, meth)
	@slot["actions/#{name}"].set_proc method(meth)
      end
      
      # prompt a message of type (INFO, WARNING or ERROR).
      # INFO is the default
      def prompt_info(msg)
	@status_line.setTextColor(@info_color)
	@status_line.setNormalText(msg)
	@status_line.forceRefresh # make sure the UI is updated in sync
      end
      
      def prompt_warning(msg)
	@status_line.setTextColor(@warning_color)
	@status_line.setNormalText("WARNING: "+msg)
	@status_line.forceRefresh # make sure the UI is updated in sync
      end
      
      def prompt_error(msg)
	@status_line.setTextColor(@error_color)
	@status_line.setNormalText("ERROR: "+msg)
	@status_line.forceRefresh # make sure the UI is updated in sync
      end
      
      def clear
	prompt('')
      end
   
    end
  end
end

