module FreeRIDE 

  module FoxRenderer
    
    class FileTree < Fox::FXTreeList
      include Fox
      
      def initialize(parent, plugin)
        super(parent, 0, nil, 0,
              (Fox::TREELIST_BROWSESELECT|Fox::TREELIST_SHOWS_LINES|Fox::TREELIST_SHOWS_BOXES|
               Fox::TREELIST_ROOT_BOXES|Fox::LAYOUT_FILL_X|Fox::LAYOUT_FILL_Y) )
        
        @plugin = plugin
        #self.connect(Fox::SEL_SELECTED){|sender, sel, item|
        self.connect(Fox::SEL_COMMAND) do |sender, sel, item|
          getApp.beginWaitCursor
          on_selected(item)
          getApp.endWaitCursor
        end
        self.connect(Fox::SEL_EXPANDED) do |sender, sel, item|
          getApp.beginWaitCursor
          on_expanded(item)
          getApp.endWaitCursor
        end
        self.connect(Fox::SEL_COLLAPSED) do |sender, sel, item|
          getApp.beginWaitCursor
          on_collapsed(item)
          getApp.endWaitCursor
        end
      end
      
      def add_node(node, name)
        unless node
          addItemLast(node, name)
        else
          addItemAfter(node, name)
        end
      end
      
      def add_child_node(node, name, icon=nil)
        if icon
          addItemLast(node, name, icon, icon)
        else
          addItemLast(node, name)
        end
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
