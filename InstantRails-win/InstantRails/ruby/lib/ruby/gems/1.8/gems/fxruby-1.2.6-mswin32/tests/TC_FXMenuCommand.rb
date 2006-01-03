require 'test/unit'
require 'testcase'
require 'fox12'

include Fox

class TC_FXMenuCommand < TestCase
  def setup
    super(self.class.name)
    @menuCommand = FXMenuCommand.new(mainWindow, "menuCommand")
  end
  
  def test_checked?
    @menuCommand.check
    assert(@menuCommand.checked?)
    @menuCommand.uncheck
    assert(!@menuCommand.checked?)
  end
  
  def test_radioChecked?
    @menuCommand.checkRadio
    assert(@menuCommand.radioChecked?)
    @menuCommand.uncheckRadio
    assert(!@menuCommand.radioChecked?)
  end
end
