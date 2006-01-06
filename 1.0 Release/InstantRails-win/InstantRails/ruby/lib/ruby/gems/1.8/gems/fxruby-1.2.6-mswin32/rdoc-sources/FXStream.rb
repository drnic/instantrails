module Fox
  #
  # Persistent store definition
  #
  # === Stream status codes
  #
  # +FXStreamOK+::		OK
  # +FXStreamEnd+::		Try read past end of stream
  # +FXStreamFull+::		Filled up stream buffer or disk full
  # +FXStreamNoWrite+::		Unable to open for write
  # +FXStreamNoRead+::		Unable to open for read
  # +FXStreamFormat+::		Stream format error
  # +FXStreamUnknown+::		Trying to read unknown class
  # +FXStreamAlloc+::		Alloc failed
  # +FXStreamFailure+::		General failure
  #
  # === Stream data flow direction
  #
  # +FXStreamDead+::		Unopened stream
  # +FXStreamSave+::		Saving stuff to stream
  # +FXStreamLoad+::		Loading stuff from stream
  #
  # === Stream seeking
  #
  # +FXFromStart+::		Seek from start position
  # +FXFromCurrent+::		Seek from current position
  # +FXFromEnd+::		Seek from end position
  #
  class FXStream

    # Stream status [Integer]
    attr_reader :status

    # Stream direction, one of +FXStreamSave+, +FXStreamLoad+ or +FXStreamDead+.
    attr_reader :direction
  
    # Parent object [FXObject]
    attr_reader :container

    # Available buffer space
    attr_accessor :space

    # Stream position (an offset from the beginning of the stream) [Integer]
    attr_accessor :position
  
    #
    # Construct stream with given container object.  The container object
    # is an object that will itself not be saved to or loaded from the stream,
    # but which may be referenced by other objects.  These references will be
    # properly saved and restored.
    #
    # ==== Parameters:
    #
    # +cont+::	the container object, or +nil+ if there is none [FXObject].
    #
    def initialize(cont=nil) # :yields: theStream
    end
  
    #
    # Open stream for reading or for writing.
    # An initial buffer size may be given, which must be at least 16 bytes.
    # If _data_ is not +nil+, it is expected to point to an external data buffer
    # of length _size_; otherwise the stream will use an internally managed buffer.
    # Returns +true+ on success, +false+ otherwise.
    #
    # ==== Parameters:
    #
    # +save_or_load+::	access mode, either +FXStreamSave+ or +FXStreamLoad+ [Integer]
    # +size+::		initial buffer size [Integer]
    # +data+::		external data buffer (if any) [String]
    #
    def open(save_or_load, size=8192, data=nil); end
  
    #
    # Close stream; returns +true+ if OK.
    #
    def close(); end
  
    #
    # Flush buffer
    #
    def flush(); end

    #
    # Get available buffer space
    #
    def getSpace(); end
  
    #
    # Set available buffer space
    #
    def setSpace(sp); end

    #
    # Return +true+ if at end of file or error.
    #
    def eof?; end

    #
    # Set status code, where _err_ is one of the stream status
    # codes listed above.
    #
    def error=(err); end

    # Set the byte-swapped flag to +true+ or +false+.
    def bytesSwapped=(swapBytes); end
    
    # Returns +true+ if bytes are swapped for this stream
    def bytesSwapped?; end
  
    # Returns +true+ if little-endian architecture
    def FXStream.littleEndian?; end
  end
end

