# Purpose: FreeRIDE constant declarations and module inclusion
#    
# $Id: freeride.rb,v 1.20 2006/06/04 12:13:30 ljulliar Exp $
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
# Copyright (c) 2001 Rich Kilmer. All rights reserved.
#

require 'rbconfig'
require 'getoptlong'
opts = GetoptLong.new(['--codebase', '-b', GetoptLong::REQUIRED_ARGUMENT ],
                      ['--project', '-p', GetoptLong::REQUIRED_ARGUMENT ] 
                     )

# See if a code base was passed as an argument. If not
# default the codebase to the path of the freeride.rb script
codebase = File.expand_path(File.dirname($0))
project = nil

$FR_CODEBASE = codebase
$FR_PROJECT = project

# prepend the include path that are needed by FR
# make sure architecture specific directory is in the include path and before
# all system standard path
$:.unshift(File.join(codebase,"freebase","lib"))
$:.unshift(File.join(codebase,"redist"))
$:.unshift(File.join(codebase,'redist', Config::CONFIG['arch']))

require 'freebase/freebase'

module FreeRIDE

  include Config

  #version information
  VERSION_MAJOR = 0
  VERSION_MINOR = 9
  VERSION_RELEASE = 6
  
  ##
  # Start up FreeRIDE and block until shut down event is received
  #
  # dir:: [String] The directory which holds the FreeRIDE codebase
  # 
  #
  def FreeRIDE.startup(dir)
    
    # verify the existence of the config directory (relative to codebase 
    # if relative path given)
    if File.absolute_path?(dir)
      configDir = dir
    else
      configDir = File.join($FR_CODEBASE,dir)
    end
      
    begin
      files = Dir.entries(configDir)
    rescue
      raise "Could not locate directory #{configDir}"
    end

    #make sure that either properties.yaml exists or default.yaml
    unless files.include?("properties.yaml")
      raise "Could not locate default.yaml in #{configDir}" unless files.include?("default.yaml")
    end
    
    #This method will not return until FreeRIDE is closed (shut down)
    FreeBASE::Core.startup("properties.yaml","#{dir}/default.yaml") do |core|
      #This method will not return until FreeRIDE is closed (shut down)
      #trap("INT") do
      #  core.bus["/system/shutdown"].call(2)
      #end
    end
  end

end

def usage
  puts "FreeRIDE, version #{FreeRIDE::VERSION_MAJOR}.#{FreeRIDE::VERSION_MINOR}.#{FreeRIDE::VERSION_RELEASE}\n"
  puts "usage: #{$0} [-b|--codebase path] [-p|--project projectfile] [-h|--help] files..." # [-p|--project projectfile]
  puts "   -b, --codebase: point freeride to a different FreeRIDE base directory"
  puts "   -p, --project: open the project at startup (not yet implemented)"
  puts "   -h, --help: print this help message"
  puts "   files: open the files at startup"
end

if $0==__FILE__

  begin
    opts.each do |opt, arg|
      case opt
      when /(-b|--codebase)/
	codebase = arg
      when /(-p|--project)/
	project = arg
      when /(-h|--help)/
	usage
	exit
      end
    end
  rescue GetoptLong::InvalidOption
    usage
    exit 1
  end

  configDir = File.join(File.dirname(File.expand_path($0)), "config")
  FreeRIDE.startup(configDir)
end

