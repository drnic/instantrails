#!/usr/bin/env ruby

begin
require 'rubygems'
require_gem 'fxruby', '>= 1.2.0'
rescue LoadError
require 'fox12'
end
require 'rubyide_fox_gui/fxscintilla/scintilla'

include Fox

ABOUT_MSG = <<EOM
The FOX GUI toolkit is developed by Jeroen van der Zijp.
The Scintilla source code editing component is developed by Neil Hodgson.
The FXScintilla widget is developed by Gilles Filippini.
The Scintilla-Ruby binding is developed by by Richard Kilmer
and FXRuby is developed by Lyle Johnson.
EOM

class ScintillaTest  < FXMainWindow

  def initialize(app)
    # Invoke base class initialize method first
    super(app, "Scintilla Test", nil, nil, DECOR_ALL, 0, 0, 800, 600)

    # Menubar
    menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Status bar
    FXStatusBar.new(self,
      LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|STATUSBAR_WITH_DRAGCORNER)

    # Scintilla widget takes up the rest of the space
    sunkenFrame = FXHorizontalFrame.new(self,
      FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @scintilla = FXScintilla.new(sunkenFrame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @controller = ScintillaController.new(@scintilla)
    @scintilla.connect(SEL_COMMAND) do |sender, sel, scn|
      @controller.handle_notification(scn.nmhdr.idFrom, scn.nmhdr.code, scn)
        #scn.nmhdr.code, scn.position, scn.ch, scn.modifiers,
        #scn.modificationType, scn.text, scn.length, scn.linesAdded,
        #scn.message, scn.wParam, scn.lParam, scn.line, scn.foldLevelNow,
        #scn.foldLevelPrev, scn.margin, scn.listType, scn.x, scn.y)
    end
    @controller.setup

    # File menu
    filemenu = FXMenuPane.new(self)
    FXMenuCommand.new(filemenu, "&Open\tCtl-O\tOpen File...").connect(SEL_COMMAND) {
      openDialog = FXFileDialog.new(self, "Open Document")
      openDialog.selectMode = SELECTFILE_EXISTING
      openDialog.patternList = ["All Files (*.*)", "Ruby Files (*.rb)"]
      if openDialog.execute != 0
        loadFile(openDialog.filename)
      end
    }
    FXMenuCommand.new(filemenu, "&Save\tCtl-S\tSave File...").connect(SEL_COMMAND) {
      @controller.save
    }
    FXMenuCommand.new(filemenu, "&Quit\tCtl-Q\tQuit application.", nil,
      getApp(), FXApp::ID_QUIT, 0)
    FXMenuTitle.new(menubar, "&File", nil, filemenu)

    # Edit menu
    editmenu = FXMenuPane.new(self)
    FXMenuCommand.new(editmenu, "Cut\tCtl-X\tCut...").connect(SEL_COMMAND) {
      @controller.cut
    }
    FXMenuCommand.new(editmenu, "Copy\tCtl-C\tCopy...").connect(SEL_COMMAND) {
      @controller.copy
    }
    FXMenuCommand.new(editmenu, "Paste\tCtl-V\tPaste...").connect(SEL_COMMAND) {
      @controller.paste
    }
    FXMenuCommand.new(editmenu, "Dump\t\tList Fold Levels...").connect(SEL_COMMAND) {
      @controller.model.line_count.times do |i|
        puts "#{@controller.model.get_fold_level(i)} #{@controller.model.get_line(i)}"
      end
    }
    FXMenuTitle.new(menubar, "&Edit", nil, editmenu)
    
    @controller.open("tmp.rb")


    # Help menu
    helpmenu = FXMenuPane.new(self)
    FXMenuCommand.new(helpmenu, "&About FXRuby...").connect(SEL_COMMAND) {
      FXMessageBox.information(self, MBOX_OK, "About FXRuby", ABOUT_MSG)
    }
    FXMenuTitle.new(menubar, "&Help", nil, helpmenu, LAYOUT_RIGHT)
  end

  def loadFile(filename)
    begin
      getApp().beginWaitCursor()
      @controller.open(filename)
    ensure
      getApp().endWaitCursor()
    end
  end

  # Start
  def create
    super
    show(PLACEMENT_SCREEN)
  end
end

if __FILE__ == $0
  # Make application
  application = FXApp.new("ScintillaTest", "FoxTest")

  # Open display
  application.init(ARGV)

  # Make window
  ScintillaTest.new(application)

  # Create app
  application.create

  # Run
  application.run
end
