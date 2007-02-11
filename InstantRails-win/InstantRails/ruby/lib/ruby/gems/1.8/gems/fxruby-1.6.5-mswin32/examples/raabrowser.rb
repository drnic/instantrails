require 'cgi'
require 'fox16'
begin
  require 'RAA'
rescue LoadError
  require 'fox16/missingdep'
  MSG = <<EOM
  Sorry, this example depends on the SOAP4R extension. Please
  check the Ruby Application Archives for an appropriate
  download site.
EOM
  missingDependency(MSG)
end

include Fox

class RAABrowserWindow < FXMainWindow
  def initialize(app)
    # Initialize base class
    super(app, "Ruby Application Archive", nil, nil, DECOR_ALL, 0, 0, 600, 600)
    
    # Contents
    contents = FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)

    # Horizontal splitter
    splitter = FXSplitter.new(contents, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|
      LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_HORIZONTAL))

    # Create a sunken frame to hold the tree list
    groupbox = FXGroupBox.new(splitter, "Contents",
      LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
    frame = FXHorizontalFrame.new(groupbox,
      LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK)

    # Create the empty tree list
    @treeList = FXTreeList.new(frame, nil, 0,
      (TREELIST_BROWSESELECT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|
       TREELIST_ROOT_BOXES|LAYOUT_FILL_X|LAYOUT_FILL_Y))
    @treeList.connect(SEL_COMMAND) do |sender, sel, item|
      if @treeList.isItemLeaf(item)
        getApp().beginWaitCursor do
          begin
	    info = @raa.getInfoFromName(item.text)
	    @category.value = info.category.major + "/" + info.category.minor
	    @projectName.value = info.product.name
	    @version.value = info.product.version
	    @status.value = info.product.status
	    @lastUpdate.value = info.update.strftime("%F %T GMT")
	    @owner.value = "#{info.owner.name} (#{info.owner.email.to_s})"
	    @homepage.value = info.product.homepage.to_s
	    @download.value = info.product.download.to_s
	    @license.value = info.product.license
	    @description.value = CGI::unescapeHTML(info.product.description).gsub(/\r\n/, "\n")
	  rescue SOAP::PostUnavailableError => ex
	    getApp().endWaitCursor
	    FXMessageBox.error(self, MBOX_OK, "SOAP Error", ex.message)
	  end
        end
      end
    end

    # Set up data targets for the product-specific information
    @category = FXDataTarget.new("")
    @projectName = FXDataTarget.new("")
    @version = FXDataTarget.new("")
    @status = FXDataTarget.new("")
    @lastUpdate = FXDataTarget.new("")
    @owner = FXDataTarget.new("")
    @homepage = FXDataTarget.new("")
    @download = FXDataTarget.new("")
    @license = FXDataTarget.new("")
    @description = FXDataTarget.new("")
    
    # Information appears on the right-hand side
    infoFrame = FXVerticalFrame.new(splitter, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT|FRAME_SUNKEN|FRAME_THICK)

    infoBox = FXGroupBox.new(infoFrame, "Info", GROUPBOX_NORMAL|LAYOUT_FILL_X|FRAME_GROOVE)
    infoMatrix = FXMatrix.new(infoBox, 2, MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXLabel.new(infoMatrix, "Category:")
    FXTextField.new(infoMatrix, 20, @category, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Project name:")
    FXTextField.new(infoMatrix, 20, @projectName, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Version:")
    FXTextField.new(infoMatrix, 20, @version, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Status:")
    FXTextField.new(infoMatrix, 20, @status, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Last update:")
    FXTextField.new(infoMatrix, 20, @lastUpdate, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Owner:")
    FXTextField.new(infoMatrix, 20, @owner, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Homepage:")
    FXTextField.new(infoMatrix, 20, @homepage, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "Download:")
    FXTextField.new(infoMatrix, 20, @download, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    FXLabel.new(infoMatrix, "License:")
    FXTextField.new(infoMatrix, 20, @license, FXDataTarget::ID_VALUE, TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)

    descriptionBox = FXGroupBox.new(infoFrame, "Description", GROUPBOX_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
    descriptionFrame = FXHorizontalFrame.new(descriptionBox, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    FXText.new(descriptionFrame, @description, FXDataTarget::ID_VALUE, TEXT_READONLY|TEXT_WORDWRAP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
      
    # Initialize the service
    @raa = RAA::Driver.new
    
    # Set up the product tree list
    @productTree = @raa.getProductTree
    @productTree.keys.sort.each do |sectionName|
      sectionHash = @productTree[sectionName]
      sectionItem = @treeList.addItemLast(nil, sectionName)
      sectionHash.keys.sort.each do |categoryName|
        categoryArray = sectionHash[categoryName]
        categoryItem = @treeList.addItemLast(sectionItem, categoryName)
        categoryArray.each do |productName|
          productItem = @treeList.addItemLast(categoryItem, productName)
        end
      end
    end
  end
  
  def create
    super
    @treeList.parent.parent.setWidth(@treeList.font.getTextWidth('M'*24))
    show(PLACEMENT_SCREEN)
  end
end

if __FILE__ == $0
  app = FXApp.new("RAABrowser", "FoxTest")
  RAABrowserWindow.new(app)
  app.create
  app.run
end
