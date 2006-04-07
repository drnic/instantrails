# Purpose: 
#
# $Id: basic_parser.rb,v 1.8 2005/10/21 11:23:26 jonathanm Exp $
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
require 'digest/sha1'

class BasicRubyParser
  class Node
    FILE = 0
    MODULE = 1
    CLASS = 2
    METHOD = 3
    SINGLETON_METHOD = 4
    
    attr_accessor :nodes, :node_type, :text, :line, :parent
    attr_reader :indent
    
    def initialize(node_type, text, line, parent = nil)
      @nodes = []
      @node_type = node_type
      @text = text
      @line = line
      @parent = parent
      @last_hash = nil
    end
    def indent
      return -1 if @node_type == FILE
      @text.index(/[^\s]/)
    end
    def to_s
      return "" unless @text
      @text.strip.split(" ")[1..-1].join(" ")
    end
    def add_node(node)
      @nodes << node
      node.parent = self
    end
    def each_node(&block)
      @nodes.each do |node| 
        yield node
        node.each_node(&block)
      end
    end
  end
  
  def each_node(&block)
    @root.each_node(&block)
  end
  
  attr_reader :root
  
  def initialize
    clear
  end
  
  def clear
    @root = Node.new(Node::FILE, nil, 1)
  end
  
  def parse(data)
    hash = Digest::SHA1.new(data).digest
    if hash==@last_hash
      return @root
    else
      clear
    end
    @last_hash = hash
    num = 0
    node = nil
    current = @root
    last = current
    comment_block = false
    here_block = false
    here_name = nil
    data.each_line do |line|
      num += 1
      # the inner loop handles multiple statements on the same line
      # separated by ";" (line number must *not* be incremented)
      line.split(/;/).each do |line|
        
        next if line.strip[0]==?#
        
        comment_block = true if line.scan(/^[=]begin/).length > 0
        if line.scan(/^[=]end/).length > 0
          comment_block = false
          next
        end
        next if comment_block
        
        if line.scan(/\<\<[-]?[\']?(\w*)[\']?(\s*)$/).length > 0
          here_block = true
          here_name = $1
        end
        if here_block and line.scan(/^(\s*)#{here_name}(\s*)$/).length > 0
          here_block = false
          next
        end
        next if here_block

	# strip out comment at end of line to avoid confusion
	# in case it contains reserved keywords
	line.gsub!(/\#.*$/,'')
        
        case line
        when /\s*class\s+[A-Z][A-Za-z0-9\_]*\s*/
          line.gsub!(/\t/, "  ")
          node = Node.new(Node::CLASS, line, num)
          if node.indent > last.indent && last.node_type < 3
            current = last
          elsif node.indent < last.indent
            current = current.parent
          end
          current.add_node(node)
          last = node
        when /\s*module\s+[A-Z][A-Za-z0-9\_]*\s*/
          line.gsub!(/\t/, "  ")
          node = Node.new(Node::MODULE, line, num)
          if node.indent > last.indent && last.node_type < 3
            current = last
          elsif node.indent < last.indent
            current = current.parent
          end
          current.add_node(node)
          last = node
        when /\s*def\s+[A-Za-z0-9\_]+\.[A-Za-z0-9\_\[\]]+\s*/
          line.gsub!(/\t/, "  ")
          node = Node.new(Node::SINGLETON_METHOD, line, num)
          if node.indent > last.indent && last.node_type < 3
            current = last
          elsif node.indent < last.indent
            current = current.parent
          end
          current.add_node(node)
          last = node
        when /\s*def\s+[A-Za-z0-9\_\[\]]+\s*/
          line.gsub!(/\t/, "  ")
          node = Node.new(Node::METHOD, line, num)
          if node.indent > last.indent && last.node_type < 3
            current = last
          elsif node.indent < last.indent
            current = current.parent
          end
          current.add_node(node)
          last = node
        end
      end
    end
    @root
  end
  def dump
    each_node { |node| puts "#{' '*node.indent}#{node} - #{node.line}" }
  end
end

