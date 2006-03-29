# Purpose: Management of code completion sequences
#
# $Id: code_template.rb,v 1.2 2005/03/11 22:09:33 ljulliar Exp $
#
# Authors:  Laurent Julliard <laurent AT moldus dot org>
# Contributors:
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Laurent Julliard. All rights reserved.
#


module FreeRIDE
  module Objects

    CURSOR_MARKER = "%^%"
    SELECTION_MARKER = "%s%"

    DEFAULT_CODE_TEMPLATES= {

      "Ruby" => {
	"aa" => ["Attribute accessor","attr_accessor #{CURSOR_MARKER}", false],
	"ar" => ["Attribute reader","attr_reader #{CURSOR_MARKER}", false],
	"aw" => ["Attribute writer","attr_writer #{CURSOR_MARKER}", false],
	"c" => ["Class definition","class #{CURSOR_MARKER}Name\n\t\nend # of Name\n", false],
	"ci" => ["Class definition with init and attributes","class #{CURSOR_MARKER}Name\n\n\tattr_reader \n\tattr_writer\n\n\tdef initialize()\n\t\t\n\tend\nend # of Name\n", false],
	"cw" => ["case-when-else-end block","case #{CURSOR_MARKER}\n\twhen\n\t\t\n\telse\n\t\nend\n", false],
	"d" => ["method definition","def #{CURSOR_MARKER}name()\n\t\nend # of name\n", false],
	"e" => ["each block iterator",".each { |v| \n\t%^%\n}\n", false],
	"ep" => ["each_pair block iterator",".each_pair { |k,v| \n\t%^%\n}\n", false],
	"fo" => ["File open","File.open(#{CURSOR_MARKER}filename,mode) { |f|\n\t\n}\n", false],
	"i" => ["If-end block","if #{CURSOR_MARKER}\n\t\nend\n", false],
	"ie" => ["If-else-end block","if #{CURSOR_MARKER}\n\t\nelse\n\t\nend\n", false],
	"iee" => ["If-else-elsif-end block","if #{CURSOR_MARKER}\n\t\nelsif\n\t\nelse\n\t\nend\n", false],
	"m" => ["Module definition","Module #{CURSOR_MARKER}Name\n\t\nend # of Name\n", false],
	"r" =>["Rescue block (around selection if any)", "begin\n\t#{SELECTION_MARKER}\nrescue => e\n\t\%^%\nend\n", false]
      }
    }

    class CTemplate

      attr_accessor :name, :description, :template, :collection, :custom
      def initialize(name, description, template, collection="Ruby", custom=true)
	@name = name
	@description = description
	@template = template
	@collection = collection
	@custom = custom
      end

      # expand the template
      # selection: text selection from the editor
      # place_holders: a Hash table with place holder name => value
      # return the expanded text and the cursor position and whether 
      # text selection was used or not
      def expand(selection="", place_holders={}, line_indent=0, indent=2)
	#puts "selection: |#{selection}|"
	#puts "li = #{line_indent}, i = #{indent}"

	# expand the tabs and add the indent at the beginning of line in template
	text = @template.gsub(/\n/, "\n"+" "*line_indent).gsub(/\t/, " "*indent)

	# delete the indent of the selection to align on the first line...
	selection.gsub!(/^ {0,#{line_indent}}/,"")
	#puts "selection after cleaning: #{selection}"
	
	# and reindent the selection to align it properly in the template
	if text =~ /^( *)#{SELECTION_MARKER}/
	  selection.gsub!(/^[ \t]*/,$1)
	  #puts "selection after realinging: #{selection}"
	end
	text = " "*line_indent + text.gsub(/^( *)#{SELECTION_MARKER}/,selection)
	return text.delete(CURSOR_MARKER), text.index(CURSOR_MARKER) || 0, !@template.index(SELECTION_MARKER).nil?
      end

      # return the list of place holders we must ask the
      # user to fill out.
      def place_holders
      end

    end


    class CCTemplateStore < Hash

      include FreeRIDE::Objects

      def initialize()
	super(Hash.new)
	DEFAULT_CODE_TEMPLATES.each_key do |collection|
	  DEFAULT_CODE_TEMPLATES[collection].each_pair do |k,v|
	    self[collection][k] = CTemplate.new(k,v[0],v[1],collection, v[2])
	  end
	end
      end

      def add(seq_name, ccseq, collection="Ruby")
	self[name] = ccseq
      end

      def remove(name)
	self[name].delete
      end

    end


    CODE_TEMPLATES = CCTemplateStore.new


  end

end
