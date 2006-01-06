#!/usr/bin/env ruby

require 'fox12'

include Fox

class HeaderWindow < FXMainWindow

  def create
    super
    show(PLACEMENT_SCREEN)
  end

  def initialize(app)
    # Invoke base class initializer first
    super(app, "Header Control Test", nil, nil, DECOR_ALL, 0, 0, 800, 600)

    # Menu bar stretched along the top of the main window
    menubar = FXMenuBar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

    # Status bar, stretched along the bottom
    FXStatusBar.new(self, LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
  
    # File menu
    filemenu = FXMenuPane.new(self)
    FXMenuCommand.new(filemenu, "&Quit\tCtl-Q\tQuit the application", nil,
      getApp(), FXApp::ID_QUIT)
    FXMenuTitle.new(menubar, "&File", nil, filemenu)

    # Help menu
    helpmenu = FXMenuPane.new(self)
    FXMenuCommand.new(helpmenu, "&About Header...").connect(SEL_COMMAND) {
      FXMessageBox.information(self, MBOX_OK, "About Header",
        "An example of how to work with the header control.")
    }
    FXMenuTitle.new(menubar, "&Help", nil, helpmenu, LAYOUT_RIGHT)

    # Make Main Window contents
    contents = FXVerticalFrame.new(self,
      FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y,
      0,0,0,0, 0,0,0,0, 0,0)
  
    # Make header control
    @header1 = FXHeader.new(contents, nil, 0,
      HEADER_BUTTON|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
    @header1.connect(SEL_CHANGED) { |sender, sel, which|
      @lists[which].width = @header1.getItemSize(which)
    }
    @header1.connect(SEL_COMMAND) { |sender, sel, which|
      @lists[which].numItems.times do |i|
        @lists[which].selectItem(i)
      end
    } 

    # Document icon
    doc = nil
    File.open(File.join("icons", "minidoc.png"), "rb") { |f|
      doc = FXPNGIcon.new(getApp(), f.read)
    }
  
    @header1.appendItem("Name", doc, 150)
    @header1.appendItem("Type", nil, 140)
    @header1.appendItem("Layout Option", doc, 230)
    @header1.appendItem("Attributes", nil, 80)
 
    # Below header
    panes = FXHorizontalFrame.new(contents,
      FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y,
      0,0,0,0, 0,0,0,0, 0,0)

    # Make 4 lists
    @lists = []
    @lists.push(FXList.new(panes, nil, 0,
      LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LIST_BROWSESELECT, 0, 0, 150, 0))
    @lists.push(FXList.new(panes, nil, 0,
      LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LIST_SINGLESELECT, 0, 0, 140, 0))
    @lists.push(FXList.new(panes, nil, 0,
      LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LIST_MULTIPLESELECT, 0, 0, 230, 0))
    @lists.push(FXList.new(panes, nil, 0,
      LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LIST_EXTENDEDSELECT, 0, 0, 80, 0))

    @lists[0].backColor = FXRGB(255, 240, 240)
    @lists[1].backColor = FXRGB(240, 255, 240)
    @lists[2].backColor = FXRGB(240, 240, 255)
    @lists[3].backColor = FXRGB(255, 255, 240)

    # Add some contents
    @lists[0].appendItem("Matsumoto Yukihiro")
    @lists[0].appendItem("Jeroen van der Zijp")
    @lists[0].appendItem("Lyle Johnson")
    @lists[0].appendItem("Andy Hunt")
    @lists[0].appendItem("Dave Thomas")
    @lists[0].appendItem("Charles Warren")

    @lists[1].appendItem("Father of Ruby")
    @lists[1].appendItem("Incorrigible Hacker")
    @lists[1].appendItem("Windows Hacker")
    @lists[1].appendItem("Pragmatic Hacker")
    @lists[1].appendItem("Ruby Hacker")
    @lists[1].appendItem("Shutter Hacker")

    @lists[2].appendItem("LAYOUT_FILL_X|LAYOUT_FILL_Y")
    @lists[2].appendItem("LAYOUT_FILL_Y")
    @lists[2].appendItem("LAYOUT_NORMAL")
    @lists[2].appendItem("LAYOUT_NORMAL")
    @lists[2].appendItem("LAYOUT_NORMAL")
    @lists[2].appendItem("LAYOUT_NORMAL")

    @lists[3].appendItem("A")
    @lists[3].appendItem("B")
    @lists[3].appendItem("C")
    @lists[3].appendItem("D")
    @lists[3].appendItem("E")
    @lists[3].appendItem("F")

    @header2 = FXHeader.new(panes, nil, 0,
      HEADER_VERTICAL|HEADER_BUTTON|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y)
    @header2.appendItem("Example", nil, 30)
    @header2.appendItem("Of", nil, 30)
    @header2.appendItem("Vertical", nil, 30)
    @header2.appendItem("Header", nil, 30)

    # Group box with some controls
    groupie = FXGroupBox.new(panes, "Controls",
      GROUPBOX_TITLE_CENTER|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    check = FXCheckButton.new(groupie,
      "Continuous Tracking\tContinuous\tTrack Header continuously",
      nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP).connect(SEL_COMMAND) {
      @header1.headerStyle ^= HEADER_TRACKING
      @header2.headerStyle ^= HEADER_TRACKING
    }

    # Whip out a tooltip control, jeez, that's hard
    FXToolTip.new(getApp())
  end
end

if __FILE__ == $0
  # Construct a FOX application object
  application = FXApp.new("Header", "FoxTest")

  # Construct the main window
  HeaderWindow.new(application)

  # Create all the windows
  application.create

  # Run the application
  application.run
end
