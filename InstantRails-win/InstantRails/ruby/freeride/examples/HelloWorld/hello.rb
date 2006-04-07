# Purpose: This is a sample plugin, clone and modify it to
# create your own plugin.
#
# $Id: hello.rb,v 1.2 2003/01/08 06:22:49 curthibbs Exp $
#
# Authors:  Curt Hibbs
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Curt Hibbs All rights reserved.
#


# This module creates a namespace called MyFreeRIDELibrary in which 
# you can place any number of related FreeRIDE plugins without having to
# worry about name conflicts with other FreeRIDE plugins.
module MyFreeRIDELibrary

  # This module creates a namespace called HelloWorld. The purpose is
  # to prevent name conflicts with other plugins that I might also put
  # into MyFreeRIDELibrary.
  module HelloWorld
    
    ##
    # This class defines the the hello world plugin
    #
    class MyHelloWorld
      extend FreeBASE::StandardPlugin
      
      # initialize this plugin
      def MyHelloWorld.start(plugin)
        # Create an instance of the our command object
	      the_cmd_object = HelloCommand.new()
	
        # Add the command to the system
	      # at the databus address: "/system/ui/commands/Examples/Hello" 
	      # and give it the menu text "&Hello World"
        plugin['/system/ui/commands'].manager.add('Examples/Hello','&Hello World') do |cmd_slot|
          # This code is executed whenever our command is invoked
          the_cmd_object.say_hello(cmd_slot)
          the_cmd_object.say_goodbye(cmd_slot)
        end
        
        # Insert the command into the Tools menu
        tools_menu = plugin['/system/ui/components/MenuPane/Tools_menu'].manager
        tools_menu.add_command('Examples/Hello')
        plugin.transition(FreeBASE::RUNNING)
      end
      
      
      class HelloCommand
        
        def initialize()
          # any needed instance initialization would go here
        end
        
        # Show the hello dialog
        def say_hello(my_slot)
          # get the system command manager
          cmd_mgr = my_slot['/system/ui/commands'].manager
	  
          # invoke the MessageBox command to display our message
          cmd_mgr.command('App/Services/MessageBox').invoke('Hello',  'Hello World!')
        end
        
        # Show the goodbye dialog
        def say_goodbye(my_slot)
          # get the slot that holds the FreeRIDE version number
          v_slot = my_slot['/system/properties/version']
	  
          # get the system command manager
          cmd_mgr = my_slot['/system/ui/commands'].manager
	  
          # invoke the MessageBox command to display our message
          cmd_mgr.command('App/Services/MessageBox').invoke('Goodbye', 
            "Goodbye World!\n\nYou are running FreeRide version #{v_slot['major'].data}.#{v_slot['minor'].data}.#{v_slot['release'].data}")
        end
      
      end # class HelloCommand
    end #class MyHelloWorld

  end #module HelloWorld
end #module MyFreeRIDELibrary
