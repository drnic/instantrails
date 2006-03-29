# Purpose: Provides a subclass of FXTreeList used by the SourceBrowser
#
# $Id: source_tree.rb,v 1.5 2006/01/06 10:03:56 jonathanm Exp $
#
# Authors:  Rich Kilmer
# Contributors: Laurent Julliard
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2002 Rich Kilmer. All rights reserved.
#

module FreeRIDE 

  module FoxRenderer
    
    class SourceTree < Fox::FXTreeList
      
      def initialize(parent, plugin, opts = 0)
        super(parent, nil, 0,
              (Fox::TREELIST_BROWSESELECT|Fox::TREELIST_SHOWS_LINES|Fox::TREELIST_SHOWS_BOXES|
               Fox::TREELIST_ROOT_BOXES|Fox::LAYOUT_FILL_X|Fox::LAYOUT_FILL_Y|opts) )
        @plugin = plugin
        
        self.connect(Fox::SEL_COMMAND){|sender, sel, item|
          getApp.beginWaitCursor
          on_selected(item)
          getApp.endWaitCursor
        }
        self.connect(Fox::SEL_EXPANDED){|sender, sel, item|
          getApp.beginWaitCursor
          on_expanded(item)
          getApp.endWaitCursor
        }
        self.connect(Fox::SEL_COLLAPSED){|sender, sel, item|
          getApp.beginWaitCursor
          on_collapsed(item)
          getApp.endWaitCursor
        }
      end
      
      def add_node(node, name, icon=nil)
        unless node
          addItemLast(node, name.to_s, icon, icon)
        else
          addItemAfter(node, name.to_s, icon, icon)
        end
      end
      
      def add_child_node(node, name, icon=nil)
        addItemLast(node, name.to_s, icon, icon)
      end
      
      def add_node_before(node, name, icon=nil)
        addItemBefore(node, name.to_s, icon, icon)
      end
      
      def clear_nodes
        clearItems
      end
      
      def get_node_text(node)
        if node == root_node
          ''
        else
          getItemText(node)
        end
      end
      
      def set_node_data(node, data)
        setItemData(node, data)
      end
    
      def get_node_data(node)
        getItemData(node)
      end

      def expand(node)
        expandTree(node, true)
      end
      
      def select_node(node)
        selectItem(node, true)
        setFocus
        setCurrentItem node
      end

      def each_child(node)
        if node.nil?
          each do |child_node|
            yield child_node
          end
        else
          node.each do |child_node|
            yield child_node
          end
        end
      end
      
      def root_node
        nil
      end
      
      def scroll_to_node(node)
        h = getItemHeight(node)
        ancestors = __get_ancestors(node)
        ancestors.push(node)
      
        n = 0
        cur_node = root_node
      
        ancestors.each do |cur_anc|	  
          #print 'ancestor: '
          #p cur_anc
      
          found = false
          each_child(cur_node) do |child_node|	    
            # child_node == cur_anc
            #p n
            #print 'child: '
            #p child_node
      
            if getItemText(child_node) == getItemText(cur_anc)
              n += 1
              found = true
              cur_node = child_node
              break
            else
              n += __get_item_num(child_node)
            end
          end
          
          unless found
            return false
          end
        end
      
        y = ( n - 1 ) * h 
        #p n
        #p y
        #setFocus
        setPosition(0, -y)
      end

      def on_selected(node)
      end
      
      def on_expanded(node)
      end
      
      def on_collapsed(node)
      end
      
      # Adds the source structure to the list.
      # append can have the following values:
      # - true:  create the new node as the last child of parentNode
      # - false: create the new node after parentNode
      # - nil:   create the new node before parentNode
      #
      # The root of the new sub-tree will have source.name as it's text.
      # User-data for each of the elements is the start-line-no of the element in the source-tree
      # If no icon is provided the ruby_file icon will be used
      #
      def add_source(source_tree, parentNode, name=nil, icon=nil, append=true)
        icon = get_icon("ruby_file") unless icon
        if name.nil?
          name = source_tree.name.to_s
          data = source_tree.start_point.line_no
        else
          data = 0
        end
        
        if append.nil?
          new_node = add_node_before(parentNode, name, icon)
        elsif append == true
          new_node = add_child_node(parentNode, name, icon)
        else
          new_node = add_node(parentNode, name, icon)
        end
        set_node_data(new_node,data)
      
        source_tree.each_singleton_method do |meth|
          n = add_child_node(new_node, meth.name, get_icon("method"))
          set_node_data(n, meth.start_point.line_no)
        end
      
        source_tree.each_method do |meth|
          n = add_child_node(new_node, meth.name, get_icon("method"))
          set_node_data(n, meth.start_point.line_no)
        end
        
        source_tree.each_module do |mod|
          add_source(mod, new_node, nil, get_icon("module"))
        end
        
        source_tree.each_singleton_class do |c|
          add_source(c, new_node, nil, get_icon("class"))
        end
        
        source_tree.each_class do |klass|
          add_source(klass, new_node, nil, get_icon("class"))
        end
        
        new_node
      end
      
      def get_icon(name)
        @plugin["/system/ui/icons/SourceBrowser/#{name}"].data
      end
      

      #private
      def __get_item_num(node)
        n = 0
        if node.nil? || isItemExpanded(node)
          each_child(node) do |child|
            n += __get_item_num(child)
          end
        end
      
        if node
          n += 1
        end
        n
      end

      def __get_ancestors(node)
        result = []
        k = node
        
        while k = k.parent
          result.unshift(k)
        end 
        result
      end
     
    end
    
  end
  
end

if $0 == __FILE__
  application = FXApp.new("Browser", "FoxTest")
  application.init(ARGV)
  
  w = Fox::FXMainWindow.new(application, 'Tree', nil, nil, DECOR_ALL, 100, 100, 300, 200)
  
  menubar = FXMenuBar.new(w, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
  h_menu = FXMenuPane.new(w)
  FXMenuCommand.new(h_menu, "Scroll", nil).connect(SEL_COMMAND){
    $t.scroll_to_node($t.currentItem)
  }
  FXMenuTitle.new(menubar, "&Carry", nil, h_menu)	

  hoge_menu = FXMenuPane.new(w)
  FXMenuCommand.new(hoge_menu, "P&ublic Instance Methods", nil).connect(SEL_COMMAND){
    p $t.getFirstItem
    p $t.getLastItem
  }
  FXMenuCommand.new(hoge_menu, "Pr&otected Instance Methods", nil).connect(SEL_COMMAND){
    p $t.getNumItems
  }
  FXMenuCommand.new(hoge_menu, "Pr&ivate Instance Methods", nil).connect(SEL_COMMAND){
    p $t.getItemHeight($t.currentItem)
    p $t.getYPosition
    p $t.getContentHeight
  }
  FXMenuTitle.new(menubar, "&Options", nil, hoge_menu)	

  $t = FreeRIDE::FoxPlugins::SourceTree.new(w)

  $count = 0
  def add(parent, n)
    node = $t.add_child_node(parent, $count.to_s)
    $t.set_node_data(node, 1)
    $count += 1
    n -= 1

    if n == 0
      return 
    else
      3.times do |aaa|      
	add(node, n)
      end
    end
  end

  10.times do |aaa|
    add($t.root_node, 5)
  end

  application.create
  w.show(Fox::PLACEMENT_SCREEN)
  application.run
end
