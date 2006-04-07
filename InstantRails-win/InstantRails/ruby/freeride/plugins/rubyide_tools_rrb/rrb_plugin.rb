begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end

require 'fox12/responder'

require 'rrb/script'
require 'rrb/node'
require 'rrb/completion'
require 'rrb/rename_local_var'
require 'rrb/rename_instance_var'
require 'rrb/rename_class_var'
require 'rrb/rename_global_var'
require 'rrb/rename_method'
require 'rrb/rename_method_all'
require 'rrb/rename_constant'
require 'rrb/extract_method'
require 'rrb/move_method'
require 'rrb/pullup_method'
require 'rrb/pushdown_method'
require 'rrb/remove_parameter'
require 'rrb/extract_superclass'
require 'rrb/default_value'

module FreeRIDE
  module RRB
    include Fox
    
    class RRB

      extend FreeBASE::StandardPlugin
      def RRB.start(plugin)
        @@plugin = plugin

        register_command
        register_menu

        plugin.transition(FreeBASE::RUNNING)
      end

      def self.register_command
        cmd_manager = @@plugin['/system/ui/commands'].manager
		
        cmd_manager.add("Refactor/ExperimentalWarning", "### Refactoring Support is Experimental ###") do |cmd_slot|
          cmd_manager.command('App/Services/MessageBox').invoke("Experimental RRB Support", 
            "These are commands that invoke the experimental RRB refactoring support. Please see the detailed info at: http://freeride.rubyforge.org/wiki/wiki.pl?RefactoringSupport")
	end
	
        cmd = cmd_manager.add('Refactor/RenameLocalVariable','&Rename Local Variable') do |slot|
          RenameLocalVariableDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/ExtractMethod','&Extract Method') do |slot|
          ExtractMethodDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/RenameInstanceVariable','&Rename Instance Variable') do |slot|
          RenameInstanceVariableDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/RenameClassVariable','&Rename Class Variable') do |slot|
          RenameClassVariableDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/RenameGlobalVariable','&Rename Global Variable') do |slot|
          RenameGlobalVariableDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/RenameMethod','&Rename Method') do |slot|
          RenameMethodDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/RenameConstant','&Rename Constant') do |slot|
          RenameConstantDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/PushdownMethod','&Push Down Method') do |slot|
          PushdownMethodDialog.new(@@plugin)
        end
        cmd = cmd_manager.add('Refactor/PullupMethod','&Pull Up Method') do |slot|
          PullupMethodDialog.new(@@plugin)
        end
      end

      def self.register_menu
        refactor_menu = @@plugin["/system/ui/components/MenuPane"].manager.add("Refactor_menu")
        refactor_menu.data = "Refactor"
        refactor_menu.attr_visible = true
        refactor_menu.manager.add_command("Refactor/ExperimentalWarning")
        refactor_menu.manager.add_command("Refactor/RenameLocalVariable")
        refactor_menu.manager.add_command("Refactor/RenameInstanceVariable")
        refactor_menu.manager.add_command("Refactor/RenameClassVariable")
        refactor_menu.manager.add_command("Refactor/RenameGlobalVariable")
        refactor_menu.manager.add_command("Refactor/RenameMethod")
        refactor_menu.manager.add_command("Refactor/RenameConstant")
        refactor_menu.manager.add_command("Refactor/ExtractMethod")
        refactor_menu.manager.add_command("Refactor/PushdownMethod")
        refactor_menu.manager.add_command("Refactor/PullupMethod")

        # Things will be more better if menubar.manager#menuPanes exists...
        menus = []
        menubar = @@plugin["/system/ui/components/MenuBar/1"]
        menubar.each_slot do |slot|
          menus << slot.data
        end
        menus = menus[0..1] + [refactor_menu.path] + menus[2..-1]
        menubar.manager.menuPanes = menus
      end
    end

    def self.new_script(plugin)
      editpanes = plugin['/system/ui/components/EditPane']

      script_files = []
      syntax_errors = SyntaxErrorList.new()
      editpanes.each_slot do |editpane|
        path = editpane.data
        text = editpane['actions/get_text'].invoke()
	begin
	  script_files << ::RRB::ScriptFile.new(text, path)
	rescue ArgumentError => error
	  # this is the exception raised by ripper when a parsed file has a
	  # syntax error in it. In which case it cannot be refactored of course.
	  if error.to_s =~ /:(\d+):/m # regexp for line number extraction
	    syntax_errors.add(path,$1)
	  end
	end
      end

      return ::RRB::Script.new(script_files)
    end

    def self.rewrite_script(plugin, script)
      editpanes = plugin['/system/ui/components/EditPane']
      script.files.each do |script_file|
        editpanes.each_slot do |editpane|
          if editpane.data == script_file.path
            ext_object = editpane['actions/get_ext_object'].invoke()
            ext_object.begin_undo_action()
            ext_object.set_text(script_file.new_script)
            ext_object.end_undo_action()
          end
        end
      end
    end

    class RefactorDialog < FXDialogBox
      include Fox
      include Responder
 
      def initialize(plugin, title)
        owner = plugin["/system/ui/fox/FXMainWindow"].data
        super(owner, title, DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE)

        @plugin = plugin
        @app = plugin["/system/ui/fox/FXApp"].data
        @current_pane = plugin['/system/ui/current/EditPane']
        @filename = @current_pane.data
        @cursor_line = @current_pane['actions/get_cursor_line'].invoke
        @script = FreeRIDE::RRB.new_script(@plugin)
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onCmdAccept)

        hfr_buttons = FXHorizontalFrame.new(self, LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH|PACK_UNIFORM_HEIGHT)
        cmd_cancel = FXButton.new(hfr_buttons, "&Cancel", nil, self, ID_CANCEL, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        cmd_ok = FXButton.new(hfr_buttons, "&OK", nil, self, ID_ACCEPT, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        FXHorizontalSeparator.new(self, LAYOUT_SIDE_BOTTOM|SEPARATOR_GROOVE|LAYOUT_FILL_X)

      end
      
      def enable_refactor?
      end

      def refactor
      end

      def onCmdAccept(sender, sel, ptr)
        begin
          if enable_refactor?
            refactor
            FreeRIDE::RRB.rewrite_script(@plugin, @script)
	    unless SyntaxErrorList.empty?
	      message_box = FXMessageBox.warning(self, MBOX_OK, 'Warning', "The following files have syntax errors and could not be inspected:\n#{SyntaxErrorList.message()}\n")
	    end
          else
            message_box = FXMessageBox.error(self, MBOX_OK, 'Error', @script.error_message)
          end
        rescue
        ensure
          onCmdCancel(sender, sel, ptr)
        end
      end
      
      def onCmdCancel(sender, sel, ptr)
        @app.stopModal(self)
        self.destroy
      end
      
    end

    class RenameDialog < RefactorDialog
      def initialize(plugin, title)
        super(plugin, title)
        old_txt_field = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        FXLabel.new(old_txt_field, "Old name: ", nil, JUSTIFY_LEFT|LAYOUT_CENTER_Y)
        @txt_old_value = FXTextField.new(old_txt_field, 12, nil, 0, (FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_CENTER_Y))
        new_txt_field = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        FXLabel.new(new_txt_field, "New name: ", nil, JUSTIFY_LEFT|LAYOUT_CENTER_Y)
        @txt_new_value = FXTextField.new(new_txt_field, 12, nil, 0, (FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_CENTER_Y))
        @txt_new_value.setFocus

        @old_value =  get_word_on_cursor
        @txt_old_value.text = @old_value
        @txt_new_value.text = @old_value

        self.create
        self.show(PLACEMENT_OWNER)
        @app.runModalFor(self)
      end

      def is_delimiter(char)
        if char =~ /\s/ || "(){}\n\r-+=.#%^&*-|?<>,~`".include?(char)
          return true
        else
          return false
        end
      end

      def get_word_on_cursor
        ext_obj = @current_pane['actions/get_ext_object'].invoke
        current_pos = ext_obj.current_pos
        text_length = ext_obj.get_text_length
        buffer = ext_obj.get_text(text_length + 1)

        left = current_pos
        loop do
          left_char = buffer[left - 1, 1]
          break if left <= 0 || is_delimiter(left_char)
          left -= 1 
        end

        if current_pos == 0
          right = 0
        else
          right = current_pos - 1
        end
        loop do
          right_char = buffer[right + 1, 1]
          break if right >= text_length || is_delimiter(right_char)
          right += 1 
        end
        buffer[left..right]
      end
    end

    class RenameLocalVariableDialog < RenameDialog
      def initialize(plugin)
        super(plugin, "Rename Local Variable")
      end

      def setup_args
        method = @script.get_method_on_cursor(@filename, @cursor_line).name
        method_name = ::RRB::Method[method]
        return [method_name, @txt_old_value.text, @txt_new_value.text]        
      end

      def enable_refactor?
        return @script.rename_local_var?(*setup_args)
      end

      def refactor
        @script.rename_local_var(*setup_args)
      end
    end

    class RenameInstanceVariableDialog < RenameDialog
      def initialize(plugin)
        super(plugin, "Rename Instance Variable")
      end

      def setup_args
        namespace = @script.get_class_on_cursor(@filename, @cursor_line)
        return [namespace, @txt_old_value.text, @txt_new_value.text]
      end

      def enable_refactor?
        return @script.rename_instance_var?(*setup_args)
      end

      def refactor
        @script.rename_instance_var(*setup_args)
      end
    end

    class RenameClassVariableDialog < RenameDialog
      def initialize(plugin)
        super(plugin, "Rename Class Variable")
      end

      def setup_args
        namespace = @script.get_class_on_cursor(@filename, @cursor_line)
        return [namespace, @txt_old_value.text, @txt_new_value.text]
      end

      def enable_refactor?
        return @script.rename_class_var?(*setup_args)
      end

      def refactor
        @script.rename_class_var(*setup_args)
      end
    end

    class RenameGlobalVariableDialog < RenameDialog
      def initialize(plugin)
        super(plugin, "Rename Global Variable")
      end

      def setup_args
        [@txt_old_value.text, @txt_new_value.text]
      end

      def enable_refactor?
        return @script.rename_global_var?(*setup_args)
      end

      def refactor
        @script.rename_global_var(*setup_args)
      end
    end

    class RenameMethodDialog < RenameDialog
      def initialize(plugin)
        super(plugin, "Rename Method")
      end

      def setup_args
        namespace = @script.get_class_on_cursor(@filename, @cursor_line)
        old_methods = [::RRB::Method.new(namespace, @txt_old_value.text)]
        return [old_methods, @txt_new_value.text]
      end

      def enable_refactor?
        return @script.rename_method?(*setup_args)
      end

      def refactor
        @script.rename_method(*setup_args)
      end
    end

    class RenameConstantDialog < RenameDialog
      def initialize(plugin)
        super(plugin, "Rename Constant")
      end

      def setup_args
        namespace = @script.get_class_on_cursor(@filename, @cursor_line)
        old_const = namespace.name + '::' + @txt_old_value.text
        return [old_const, @txt_new_value.text]
      end

      def enable_refactor?
        return @script.rename_constant?(*setup_args)
      end

      def refactor
        @script.rename_constant(*setup_args)
      end
    end

    class ExtractMethodDialog < RefactorDialog
      def initialize(plugin)
        super(plugin, "Extract Method")

        hfr_txt_field = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        FXLabel.new(hfr_txt_field, "Method name: ", nil, JUSTIFY_LEFT|LAYOUT_CENTER_Y)
        @txt_new_method = FXTextField.new(hfr_txt_field, 12, nil, 0, (FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_CENTER_Y))
        @txt_new_method.setFocus

        self.create
        self.show(PLACEMENT_OWNER)
        @app.runModalFor(self)
      end

      def setup_args
        ext_obj = @current_pane['actions/get_ext_object'].invoke
        start_line =  ext_obj.line_from_position(ext_obj.selection_start) + 1
        end_line =  ext_obj.line_from_position(ext_obj.selection_end) + 1
        new_method = @txt_new_method.text

        return [@filename, new_method, start_line, end_line]
      end

      def enable_refactor?
        return @script.extract_method?(*setup_args)
      end

      def refactor
        @script.extract_method(*setup_args)
      end
    end

    class MoveMethodDialog < RefactorDialog
      def initialize(plugin, text)
        super(plugin, "Extract Method")        

        matrix = FXMatrix.new(self, 2, MATRIX_BY_COLUMNS|LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        begin
          method_candidates = @script.refactable_methods
          destination_candidates = @script.refactable_classes
        rescue
          return
        end

        FXLabel.new(matrix, "Select Target Method: ", nil, JUSTIFY_RIGHT|LAYOUT_CENTER_Y|LAYOUT_FILL_ROW)
        @cmb_target_method = FXComboBox.new(matrix,method_candidates.size,nil,0,COMBOBOX_INSERT_FIRST|FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_ROW|LAYOUT_FILL_COLUMN)
	@cmb_target_method.setNumVisible(method_candidates.size)
        method_candidates.map{|method| method.name}.each do |candidate|
          @cmb_target_method.appendItem(candidate)
        end

        FXLabel.new(matrix, "Select Destination class: ", nil, JUSTIFY_RIGHT|LAYOUT_CENTER_Y|LAYOUT_FILL_ROW)
        @cmb_destination = FXComboBox.new(matrix,destination_candidates.size,nil,0,COMBOBOX_INSERT_FIRST|FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_ROW|LAYOUT_FILL_COLUMN)
	@cmb_destination.setNumVisible(destination_candidates.size)
        destination_candidates.each do |candidate|
          @cmb_destination.appendItem(candidate)
        end

        self.create
        self.show(PLACEMENT_OWNER)
        @app.runModalFor(self)
      end
    end
    
    class PushdownMethodDialog < MoveMethodDialog
      def initialize(plugin)
        super(plugin, "Push Down Method")
      end

      def setup_args
        method_name = ::RRB::Method[@cmb_target_method.text]
        new_namespace = ::RRB::Namespace.new(@cmb_destination.text)

        return [method_name, new_namespace, @filename, @cursor_line]
      end

      def enable_refactor?
        return @script.pushdown_method?(*setup_args)
      end

      def refactor
        @script.pushdown_method(*setup_args)
      end
    end

    class PullupMethodDialog < MoveMethodDialog
      def initialize(plugin)
        super(plugin, "Pull Up Method")
      end

      def setup_args
        method_name = ::RRB::Method[@cmb_target_method.text]
        new_namespace = ::RRB::Namespace.new(@cmb_destination.text)

        return [method_name, new_namespace, @filename, @cursor_line]
      end

      def enable_refactor?

        return @script.pullup_method?(*setup_args)
      end

      def refactor
        @script.pullup_method(*setup_args)
      end
    end

    class SyntaxErrorList

      def initialize
	@@syntax_errors = Hash.new
      end

      def self.message
	msg = String.new
	@@syntax_errors.each do |k,v|
	  msg << "#{k}:#{v}\n"
	end
	return msg
      end

      def self.empty?
	return @@syntax_errors.empty?
      end

      def add(path, line)
	@@syntax_errors[path] = line
      end
    end
  end
end


