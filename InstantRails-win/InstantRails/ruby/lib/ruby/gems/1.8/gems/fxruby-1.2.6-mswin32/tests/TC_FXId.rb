require 'test/unit'
require 'fox12'
require 'testcase'

include Fox

class TC_FXId < TestCase
  def setup
    super(self.class.name)
  end

  def test_created?
    assert(!mainWindow.created?)
    theApp.create
    assert(mainWindow.created?)
    mainWindow.destroy
    assert(!mainWindow.created?)
  end
end
