# Purpose: Property-view helper classes
#
# $Id: prop_view_helpers.rb,v 1.3 2006/06/04 09:59:02 jonathanm Exp $
#
# Authors: Jonathan Maasland <nochoice AT xs4all.nl>
#
# This file is part of the FreeRIDE project
#
# This application is free software; you can redistribute it and/or
# modify it under the terms of the Ruby license defined in the
# COPYING file.
#
# Copyright (c) 2005 Jonathan Maasland All rights reserved.
#

require 'fileutils'
require 'rubyide_tools_fox_project_explorer/property_viewer'

module FreeRIDE
  module Tools
    module PropertyViewHelpers

class LOCRenderer
  def initialize(parent)
    matrix = FXMatrix.new(parent, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    FXLabel.new(matrix, "Total number of lines:")
    @total = FXLabel.new(matrix, "123")
    FXLabel.new(matrix, "Comment lines:")
    @comment = FXLabel.new(matrix, "456")
    FXLabel.new(matrix, "Whitespace lines:")
    @ws = FXLabel.new(matrix, "789")
    FXLabel.new(matrix, "Actual lines of code:")
    @actual = FXLabel.new(matrix, "0")
  end
  
  def update(total, comments, whitespace)
    actual = total - comments - whitespace
    c_p = (comments/total.to_f)*100
    w_p = (whitespace/total.to_f)*100
    a_p = 100 - c_p - w_p
    
    fmt = FreeRIDE::Tools::PropertyViewTypes::ViewType.method(:format_number)
    @total.text = fmt.call(total)
    @comment.text = "#{fmt.call(comments)} (#{fmt.call(c_p)}%)"
    @ws.text = "#{fmt.call(whitespace)} (#{fmt.call(w_p)}%)"
    @actual.text = "#{fmt.call(actual)} (#{fmt.call(a_p)}%)"
  end
end

# This class is used by the ProjectView as well as the NewProjectDialog
# It provides accessor methods for all the project-settings
class ProjectSettingsRenderer

  def initialize(parent)
    @parent = parent
  end
  
  def update(tree_item)
    @current_item = tree_item
    slot = tree_item.data["slot"]
    
    if @src_tree.nil?
      init_gui(slot)
      @parent.create
    end
    p_props = slot.manager.properties
    
    @name_tf.text = p_props["name"]
    @bdir_tf.text = p_props["basedirectory"]
    @ck_new_bdir.checkState = 0
    @default_script_tf.text = p_props["default_script"]
    @wd.text = p_props["working_dir"]
    @cl.text = p_props["cmd_line_options"]
    @sbr.checkState = (p_props["save_before_running"])? 1 : 0
    @rit.checkState = (p_props["run_in_terminal"])? 1 : 0
    
    bd_is_src = false
    @src_tree.clearItems
    p_props["source_directories"].each do |src|
      @src_tree.add_directory(src, nil)
      bd_is_src = true if src == @bdir_tf.text
    end
    @ck_bdir_is_src.checkState = (bd_is_src)? 1 : 0
    
    @req_tree.clearItems
    p_props["required_directories"].each do |req|
      @req_tree.add_directory(req, nil)
    end
    # Select the interpreter
    (0..@interpreters_lst.numItems-1).each do |i|
      if @interpreters_lst.getItemText(i) == p_props["interpreter"]
        @interpreters_lst.currentItem = i 
      end
    end
  end
  
  
  ## Accessor methods for the settings
  
  def project_name
    @name_tf.text
  end
  def basedir
    @bdir_tf.text
  end
  def create_basedir?
    @ck_new_bdir.checkState == 1
  end
  def basedir_is_src?
    @ck_bdir_is_src.checkState == 1
  end
  def source_dirs
    src_dirs = []
    #src_dirs << basedir if basedir_is_src?
    @src_tree.each do |i| src_dirs << i.text end
    src_dirs
  end
  def required_dirs
    req_dirs = []
    @req_tree.each do |i| req_dirs << i.text end
    req_dirs
  end
  def default_script
    @default_script_tf.text
  end
  def working_dir
    @wd.text
  end
  def command_line_options
    @cl.text
  end
  def interpreter
    @interpreters_lst.getItemText(@interpreters_lst.currentItem)
  end
  def save_before_running?
    @sbr.checkState == 1
  end
  def run_in_terminal?
    @rit.checkState == 1
  end
  
  def get_project_filename
    File.join(basedir, project_name) + ".frproj"
  end
  
  ##
  # Creates the basedirectory
  # Since we don't have a mkdir -p option we need to create
  # all the missing parents for the new basedirectory
  # On Windows we need to change all slashes to backslashes
  def create_basedir
    bd = basedir
    bd = bd.gsub(/\\/,"/") if RUBY_PLATFORM =~ /(mswin32)|(mingw32)/
    
    current = ""
    bd.split(File::SEPARATOR).each do |p|
      if p.length == 0
        current += File::SEPARATOR
      else
        newdir = (current.length==0)? p : File.join(current, p)
        Dir.mkdir(newdir) unless File.directory?(newdir)
        current = newdir
      end
    end
  end
  
  # Validates the presence of a project-name a valid writable base-directory
  # All other settings are optional and needn't be set (not even source dirs)
  #
  def validate_project_location
    bd = basedir
    name = project_name
    err = "Error"
    
    if name.length == 0
      show_message("Please enter a project name", err)
      return false
    end
    
    if name == "Default Project"
      show_message("Please choose a different name for your project", err)
      return false
    end
    
    if bd.length == 0
      show_message("Please enter a basedirectory for the project", err)
      return false
    end
    
    if File.exists?(get_project_filename)
      show_message("A project with the name #{name} already exists in #{bd}", err)
      return false
    end
    
    return true if create_basedir?
    
    if !File.directory?(bd)
      show_message("'#{bd}' is not a directory", err)
      return false
    end
    
    if !File.writable?(bd)
      show_message("'#{bd}' is not a writable directory", err)
      return false
    end
    
    return true
  end
  
  ## GUI creation
  def init_gui(slot)
    @slot = slot
    content_panel = FXVerticalFrame.new(@parent, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    name_panel = FXHorizontalFrame.new(content_panel, LAYOUT_FILL_X)
    FXLabel.new(name_panel, "Project name: ")
    @name_tf = FXTextField.new(name_panel, 20, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X)
    
    bdir_panel = FXHorizontalFrame.new(content_panel, LAYOUT_FILL_X)
    FXLabel.new(bdir_panel, "Base directory: ")
    @bdir_tf = FXTextField.new(bdir_panel, 40, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X)
    browse_btn = FXButton.new(bdir_panel, "Browse")
    browse_btn.connect(SEL_COMMAND, method(:select_base_dir))
    
    bdir2_p = FXHorizontalFrame.new(content_panel, LAYOUT_FILL_X,
          0, 0, 0, 0, 0, 0, 0, 0, 15) # Horizontal spacing = 15
    @ck_new_bdir = FXCheckButton.new(bdir2_p, "Create basedirectory")
    @ck_bdir_is_src = FXCheckButton.new(bdir2_p, "Base directory is a source directory")
    @ck_bdir_is_src.connect(SEL_COMMAND, method(:on_bd_is_src))
    @ck_bdir_is_src.checkState = 0
    
    
    group = FXGroupBox.new(content_panel, "Additional settings", 
          GROUPBOX_NORMAL|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @tabbook = FXTabBook.new(group, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    init_tabbook
    init_interpreters
    init_popup_menu
  end
  
  def init_tabbook
    # Source directory tab
    FXTabItem.new(@tabbook, "Source dirs")
    source_panel = FXVerticalFrame.new(@tabbook, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXLabel.new(source_panel, "List of directories to be searched for Ruby scripts")
    
    @src_tree = FreeRIDE::FoxRenderer::DirectorySourceTree.new(source_panel, @slot, 
          FRAME_SUNKEN|FRAME_THICK|TREELIST_NORMAL)
    b_panel = FXHorizontalFrame.new(source_panel, LAYOUT_FILL_X, 0, 0, 0, 0, 0, 15) 
    btn = FXButton.new(b_panel, "Add")
    btn.connect(SEL_COMMAND, method(:add_source_dir))
    btn = FXButton.new(b_panel, "Remove")
    btn.connect(SEL_COMMAND, method(:rem_source_dir))
    
    # Required-dirs tab
    FXTabItem.new(@tabbook, "Required dirs")
    req_panel = FXVerticalFrame.new(@tabbook, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXLabel.new(req_panel, "List of directories to be added to the require path")
    @req_tree = FreeRIDE::FoxRenderer::DirectorySourceTree.new(req_panel, @slot, 
          FRAME_SUNKEN|FRAME_THICK|TREELIST_NORMAL)
    
    b_panel = FXHorizontalFrame.new(req_panel, LAYOUT_FILL_X, 0, 0, 0, 0, 0, 15) 
    btn = FXButton.new(b_panel, "Add", nil, nil, 0, BUTTON_NORMAL, 0,0, 30)
    btn.connect(SEL_COMMAND, method(:add_req_dir))
    btn = FXButton.new(b_panel, "Remove", nil, nil, 0, BUTTON_NORMAL, 0,0, 30)
    btn.connect(SEL_COMMAND, method(:rem_req_dir))
    
    # Run settings tab
    FXTabItem.new(@tabbook, "Run settings")
    run_panel = FXVerticalFrame.new(@tabbook, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    tmp_panel = FXHorizontalFrame.new(run_panel, LAYOUT_FILL_X)
    FXLabel.new(tmp_panel, "Ruby interpreter: ")
    @interpreters_lst = FXComboBox.new(tmp_panel, 4, nil, 0, 
          LIST_NORMAL|LAYOUT_FILL_X|FRAME_NORMAL)
    
    tmp_panel = FXHorizontalFrame.new(run_panel, LAYOUT_FILL_X)
    FXLabel.new(tmp_panel, "Default script: ")
    @default_script_tf = FXTextField.new(tmp_panel, 40, nil, 0, 
          TEXTFIELD_NORMAL|LAYOUT_FILL_X)
    @default_script_tf.disable
    
    tmp_panel = FXHorizontalFrame.new(run_panel, LAYOUT_FILL_X)
    FXLabel.new(tmp_panel, "Working directory: ")
    @wd = FXTextField.new(tmp_panel, 40, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X)
    btn = FXButton.new(tmp_panel, "Browse")
    btn.connect(SEL_COMMAND, method(:browse_wd))
    
    tmp_panel = FXHorizontalFrame.new(run_panel, LAYOUT_FILL_X)
    FXLabel.new(tmp_panel, "Command line options: ")
    @cl = FXTextField.new(tmp_panel, 40, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X)
    
    @sbr = FXCheckButton.new(run_panel, "Save files before running/debugging")
    @rit = FXCheckButton.new(run_panel, "Run process in terminal")
  end
  
  def init_popup_menu
    src_ctx_menu = FXMenuPane.new(@parent)
    
    cmd_default = FXMenuCommand.new(src_ctx_menu, "Set as default project script")
    cmd_default.connect(SEL_COMMAND) do |sender,sel,event|
      item = @src_tree.currentItem
      @default_script_tf.text = item.data['path'].to_s
      # A change of icon could/would be nice...
    end
    
    cmd_refresh = FXMenuCommand.new(src_ctx_menu, "Refresh")
    cmd_refresh.connect(SEL_COMMAND, method(:cmd_refresh))
    
    @mnu_created = false
    @src_tree.connect(SEL_RIGHTBUTTONRELEASE) do |sender,sel,event|
      next if event.moved?
      if !@mnu_created
        src_ctx_menu.hide
        src_ctx_menu.create
        @mnu_created = true
      end
      
      item = @src_tree.cursorItem
      @src_tree.currentItem = item
      next unless item
      data = item.data
      if data.instance_of?Hash
        if data['directory'] == true
          cmd_default.hide
        else
          cmd_default.show
        end
      end
      
      src_ctx_menu.popup(nil, event.root_x, event.root_y)
      src_ctx_menu.getApp().runModalWhileShown(src_ctx_menu)
    end
  end
  
  def init_interpreters
    # Fill the interpreters list and select the currently configured default
    dbg_plugin = @slot['/plugins/rubyide_tools_debugger'].manager
    default_int = dbg_plugin.properties['default_interpreter']
    default_idx = nil
    dbg_plugin.properties['interpreters'].each do |int_name, int_settings|
      idx = @interpreters_lst.appendItem(int_name)
      default_idx = idx if int_name == default_int
    end
    @interpreters_lst.setCurrentItem(default_idx) if default_idx
    @interpreters_lst.numVisible = 4
    
  end
  
  ## GUI callback methods
  def on_bd_is_src(sender,sel,data)
    if data
      if File.exists?(basedir) and File.directory?(basedir)
        @src_tree.add_directory(basedir, nil)
      else
        @ck_bdir_is_src.checkState = 1
      end
    else
      @src_tree.each do |root|
        if root.text == basedir
          @src_tree.removeItem(root)
          break
        end
      end
    end
  end
  
  # Refreshes the currently selected item in the source-tree.
  # FIXME: extract this to a generic DirectorySourceTree method
  def cmd_refresh(sender,sel,evt)
    item = @src_tree.currentItem
    data = item.data
    
    # The item to refresh can be either a directory or a rubyscript
    # In order to maintain the order of the tree the previous and next items
    # need to be checked. If both are nil the current item is an only child and 
    # can be safely added and removed to/from it's parent.
    # See also DirectorySourceTree.add_directory
    append = true
    other_node = item.parent
    n,p = item.getNext, item.getPrev
    if p
      append = false
      other_node = p
    elsif n
      append = nil
      other_node = n
    end
    
    if data['directory']
      x = @src_tree.add_directory(data['path'], other_node, append)
    else
      x = @src_tree.add_rubyscript(data['path'], other_node, append)
    end
    x.setItemText(data['filename']) unless item.parent.nil?
    @src_tree.removeItem(item)
    @src_tree.setCurrentItem(x)
  end
  
  def add_source_dir(sender, sel, data)
    dir = browse_dir("Browse for a source directory")
    if dir
      @src_tree.add_directory(dir, nil)
    end
  end
  
  
  def add_req_dir(sender, sel, data)
    dir = browse_dir("Browse for a required directory")
    if dir
      @req_tree.add_directory(dir, nil)
    end
  end
  
  
  def rem_source_dir(sender, sel, data)
    if !remove_selected_root_from_tree(@src_tree)
      show_message "Please select a root in the tree", "Error"
    end
  end
  
  
  def rem_req_dir(sender, sel, data)
    if !remove_selected_root_from_tree(@req_tree)
      show_message "Please select a root in the tree", "Error"
    end
  end
  
  
  def select_base_dir(sender, sel, data)
    dir = browse_dir("Browse for project base directory")
    return unless dir
    
    # Remove the old basedir from the tree of source-dirs if it was added
    old = @bdir_tf.text
    if old.length > 0
      @src_tree.each do |dirEntry|
        if dirEntry.data["path"] == old
          @src_tree.removeItem(dirEntry)
          break
        end
      end
    end
    @bdir_tf.text = dir
    @src_tree.add_directory(dir, nil) if @ck_bdir_is_src.checkState == 1
  end
  
  def browse_wd(sender,sel,data)
    dir = browse_dir("Browse for project working directory")
    if dir
      @wd.text = dir
    end
  end
  
  # Removes the selected root from a tree if any is selected
  def remove_selected_root_from_tree(tree)
    itemRemoved = false
    tree.each do |root| 
      if tree.itemSelected?(root)
        itemRemoved = true
        tree.removeItem(root)
        break # Only one root can be selected
      end
    end
    itemRemoved
  end
  
  def show_message(msg, title)
    FXMessageBox.information(@parent, MBOX_OK, title, msg)
  end
  
  def browse_dir(title)
    return @slot['/system/ui/commands/App/Services/DirDialog'].invoke(@slot, title, '', @parent)
  end
end


class PermissionRenderer
  def initialize(parent)
    if RUBY_PLATFORM =~ /(mswin32|mingw32)/
      @renderer = WindowsPermissionRenderer.new(parent)
    else
      @renderer = UnixPermissionRenderer.new(parent)
    end
  end
  
  def update(item)
    @renderer.update(item)
  end
  
  def apply_changes
    @renderer.apply_changes
  end
end

class WindowsPermissionRenderer
  RO   = 0100444
  NORM = 0100644
  
  def initialize(parent)
    cpanel = FXHorizontalFrame.new(parent, LAYOUT_FILL_X)
    @ck = FXCheckButton.new(cpanel, "Read-only")
  end
  
  def update(item)
    @current_path = item.data["path"]
    if File.stat(@current_path).mode == RO
      @ck.checkState = 1
    else
      @ck.checkState = 0
    end
  end
  
  def apply_changes
    if File.stat(@current_path).mode == RO
      File.chmod(NORM, @current_path) if @ck.checkState == 0
    else
      File.chmod(RO, @current_path) if @ck.checkState == 1
    end
  end
end


class UnixPermissionRenderer
  require 'etc'
  @@groups, @@users = {}, {}
  
  def self.init_users_groups
    g,u = nil,nil
    @@groups[g.gid] = g while g = Etc.getgrent
    Etc.endgrent
    @@users[u.uid] = u while u = Etc.getpwent
    Etc.endpwent
  end
  
  def initialize(parent)
    UnixPermissionRenderer.init_users_groups if @@groups.size == 0
    
    content = FXVerticalFrame.new(parent, LAYOUT_FILL_X)
    # owner and group labels
    opanel = FXHorizontalFrame.new(content, LAYOUT_FILL_X)
    FXLabel.new(opanel, "Owner: ")
    @lbl_owner = FXLabel.new(opanel, "")
    
    gpanel = FXHorizontalFrame.new(content, LAYOUT_FILL_X)
    FXLabel.new(gpanel, "Group: ")
    @lbl_group = FXLabel.new(gpanel, "")
    
    # Build the permission-bits box
    pgb = FXGroupBox.new(content, "Permissions", 
          LAYOUT_FILL_X|LAYOUT_FILL_Y|GROUPBOX_NORMAL|FRAME_GROOVE)
    permpanel = FXVerticalFrame.new(pgb, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    pbit_panel = FXMatrix.new(permpanel, 4, MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXHorizontalFrame.new(pbit_panel) #empty cell
    %w( Read Write Execute ).each do |x| 
      FXLabel.new(pbit_panel, x, nil, LABEL_NORMAL|LAYOUT_CENTER_X) 
    end

    arr = (@read_cbs, @write_cbs, @exec_cbs = [], [], [])  #Ruby r00ls!
    %w( User Group Others ).each do |x|
      FXLabel.new(pbit_panel, x)
      3.times do |i|
        cb = FXCheckButton.new(pbit_panel, "", nil, 0, CHECKBUTTON_NORMAL|LAYOUT_CENTER_X)
        arr[i] << cb
      end
    end
    @cb_uid = FXCheckButton.new(permpanel, "Set UID")#, nil, 0, CHECKBUTTON_NORMAL|LAYOUT_FILL_X)
    @cb_gid = FXCheckButton.new(permpanel, "Set GID")#, nil, 0, CHECKBUTTON_NORMAL|LAYOUT_FILL_X)
  end
  
  
  def update(item)
    @current_path = item.data["path"]
    stat = File.stat(@current_path)
    
    # Update the owner and group labels
    @lbl_owner.text = @@users[stat.uid].name
    @lbl_group.text = @@groups[stat.gid].name
    
    # Change the permission-bit checkboxes
    can_change = File.owned?(@current_path)
    cb_arr = [ @read_cbs, @write_cbs, @exec_cbs ]
    file_mode = stat.mode
    flag, idx = 256, 0
    while flag > 0
      current_cb = cb_arr[idx%3][idx.div(3)]
      current_cb.checkState = (file_mode & flag == flag)? 1 : 0
      if can_change
        current_cb.enable
      else
        current_cb.disable
      end
      
      idx += 1
      flag = flag.div(2)
    end
    # Set GID/UID checkboxes
    @cb_uid.checkState = ((file_mode & 2048 == 2048)? 1 : 0)
    @cb_gid.checkState = ((file_mode & 1024 == 1024)? 1 : 0)
    
  end
  
  def apply_changes
    # Build the integer representing the new permissions
    nv = 0
    nv |= 16384 if File.directory?(@current_path)
    nv |= 2048 if @cb_uid.checkState == 1
    nv |= 1024 if @cb_gid.checkState == 1
    
    arr = [ @read_cbs, @write_cbs, @exec_cbs ]
    flag, idx = 256, 0
    while flag > 0
      nv |= flag if arr[idx%3][idx.div(3)].checkState == 1
      idx += 1
      flag = flag.div(2)
    end
    
    begin
      FileUtils.chmod(nv, @current_path) if nv != File.stat(@current_path).mode
    rescue
      puts $!.message
      return false
    end

    return true
  end
  
end
  
    end # module PropertyViewHelpers
  end # module Tools
end # module FreeRIDE
