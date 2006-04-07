# Purpose: Setup and initialize the core gui interfaces
#
# $Id: command_manager.rb,v 1.2 2003/05/16 14:45:06 richkilmer Exp $
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

module FreeRIDE; module Commands


class CommandManager
  extend FreeBASE::StandardPlugin
  
  def CommandManager.start(plugin)
    CommandManager.new(plugin)
    plugin.transition(FreeBASE::RUNNING)
  end
  
  def initialize(plugin)
    @plugin = plugin
    @cmd_base = @plugin["/system/ui/commands"]
    @cmd_base.manager = self
    @cmd_base.subscribe do |event, slot|
      if (event == :notify_slot_managed && slot.manager.kind_of?(Command))
        #@plugin['log/info'] << "Command added" 
      end
    end
  end
  
  def add(path, text, description=nil, &block)
    path = normalize_path(path)
    raise "Must supply block which processes command" unless block_given?
    c = Command.new(@cmd_base[path]) do |cmd|
      cmd.text = text
      cmd.description = description if description
      cmd.proc = block
    end
    return c
  end
  
  def each
    @cmd_base.each_slot(true) do |slot|
      yield slot.manager if slot.manager.kind_of? Command
    end
  end
  
  def command(path)
    path = normalize_path(path)
    return @cmd_base[path].manager
  end
  
  def delete(path)
    path = normalize_path(path)
    @cmd_base[path].prune
  end
  
  class Command
    def initialize(slot)
      @cmd_slot = slot
      @cmd_slot.manager = self
      self.availability = true
      yield self if block_given?
    end
    
    def available?
      return @cmd_slot['availability'].data
    end
    
    def availability=(value)
      @cmd_slot['availability'].data = value
    end
    
    def checked?
      return @cmd_slot['checked'].data
    end
    
    def checked=(value)
      return @cmd_slot['checked'].data = value
    end
    
    def availability_managed?
      return @av_manager ? true : false
    end
    
    def manage_availability(proc = nil, &block)
      proc = block unless proc
      @av_manager = proc
      @av_manager.call(self)
    end
    
    def monitor_availability(proc = nil, &block)
      proc = block unless proc
      @cmd_slot['availability'].subscribe do |event, slot|
        if event==:notify_data_set
          proc.call(self)
        end
      end
      @cmd_slot['checked'].subscribe do |event, slot|
        if event==:notify_data_set
          proc.call(self)
        end
      end
    end
    
    def availability_bound?
      return @av_binder ? true : false
    end
    
    def text
      return @cmd_slot['text'].data
    end
    
    def text=(text)
      @cmd_slot['text'].data = text
    end
    
    def icon
      return @cmd_slot['icon'].data
    end
    
    def icon=(path)
      @cmd_slot['icon'].data = path
    end
    
    def description
      return @cmd_slot['description'].data
    end
    
    def description=(description)
      @cmd_slot['description'].data = description
    end
    
    def proc=(proc)
      @cmd_slot.set_proc(proc)
    end
    
    def invoke(*args, &block)
      if available?
        @cmd_slot.invoke(@cmd_slot, *args, &block)
      end
    end
    
  end
  
  private
  
  def normalize_path(path)
    while(path[0]==FreeBASE::DataBus::SEPARATOR)
      path = path[1..-1]
    end
    return path
  end
  

end  # module System_Commands

end ; end
