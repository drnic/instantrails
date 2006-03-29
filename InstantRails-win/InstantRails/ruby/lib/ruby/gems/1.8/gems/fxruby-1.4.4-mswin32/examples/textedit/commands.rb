require 'fox14'
require 'fox14/undolist'

include Fox

# Undo record for text fragment
class FXTextCommand < FXCommand

  attr_reader :numCharsInserted
  attr_reader :numCharsDeleted

  def initialize(txt, p, ni, nd)
    @text = txt
    @buffer = nil
    @pos = p
    @numCharsDeleted = nd
    @numCharsInserted = ni
  end

  def size
    (@buffer != nil) ? @buffer.size : 0
  end
end

# Insert command
class FXTextInsert < FXTextCommand
  def initialize(txt, p, ni)
    super(txt, p, ni, 0)
  end

  def undoName
    "Undo insert"
  end

  def redoName
    "Redo insert"
  end

  # Undoing an insert removes the previously inserted text
  def undo
    @buffer = @text.extractText(@pos, numCharsInserted)
    @text.removeText(@pos, numCharsInserted)
    @text.cursorPos = @pos
    @text.makePositionVisible(@pos)
  end

  # Redoing an insert re-inserts the same text
  def redo
    @text.insertText(@pos, @buffer)
    @text.cursorPos = @pos + numCharsInserted
    @text.makePositionVisible(@pos + numCharsInserted)
    @buffer = nil
  end
end

# Delete command
class FXTextDelete < FXTextCommand
  def initialize(txt, p, nd)
    super(txt, p, 0, nd)
    @buffer = @text.extractText(@pos, nd)
  end

  def undoName
    "Undo delete"
  end

  def redoName
    "Redo delete"
  end

  # Undoing a delete re-inserts the deleted text
  def undo
    @text.insertText(@pos, @buffer)
    @text.cursorPos = @pos + @buffer.length
    @text.makePositionVisible(@pos + @buffer.length)
    @buffer = nil
  end

  # Redoing a delete removes it again
  def redo
    @buffer = @text.extractText(@pos, numCharsDeleted)
    @text.removeText(@pos, @buffer.length)
    @text.cursorPos = @pos
    @text.makePositionVisible(@pos)
  end
end

# Replace command
class FXTextReplace < FXTextCommand
  def initialize(txt, p, ni, nd)
    super(txt, p, ni, nd)
    @buffer = @text.extractText(@pos, nd)
  end

  def undoName
    "Undo replace"
  end

  def redoName
    "Redo replace"
  end

  # Undoing a replace reinserts the old text
  def undo
    tmp = @text.extractText(@pos, numCharsInserted)
    @text.replaceText(@pos, numCharsInserted, @buffer)
    @text.cursorPos = @pos + @buffer.length
    @text.makePositionVisible(@pos + @buffer.length)
    @buffer = tmp
  end

  # Redo a replace reinserts the new text
  def redo
    tmp = @text.extractText(@pos, numCharsDeleted)
    @text.replaceText(@pos, numCharsDeleted, @buffer)
    @text.cursorPos = @pos + numCharsInserted
    @text.makePositionVisible(@pos + numCharsInserted)
    @buffer = tmp
  end
end
