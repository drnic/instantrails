module Fox
  #
  # File item
  #
  class FXFileItem < FXIconItem
  
    # The file association object for this item [FXFileAssoc]
    attr_reader :assoc
    
    # The file size for this item [Integer]
    attr_reader :size
    
    # Date for this item [Time]
    attr_reader :date

    # Returns an initialized FXFileItem instance
    def initialize(text, bi=nil, mi=nil, ptr=nil) # :yields: theFileItem
    end
  
    # Return +true+ if this is a file item
    def file?; end
  
    # Return +true+ if this is a directory item
    def directory?; end
  
    # Return +true+ if this is a share item
    def share?; end

    # Return +true+ if this is an executable item
    def executable?; end
  
    # Return +true+ if this is a symbolic link item
    def symlink?; end
  
    # Return +true+ if this is a character device item
    def chardev?; end
  
    # Return +true+ if this is a block device item
    def blockdev?; end
  
    # Return +true+ if this is an FIFO item
    def fifo?; end
  
    # Return +true+ if this is a socket
    def socket?; end
  end

  #
  # File List object
  #
  # === File List options
  #
  # +FILELIST_SHOWHIDDEN+::	Show hidden files or directories
  # +FILELIST_SHOWDIRS+::	Show only directories
  # +FILELIST_SHOWFILES+::	Show only files
  # +FILELIST_NO_OWN_ASSOC+::	Do not create associations for files
  #
  # === Message identifiers
  #
  # +ID_SORT_BY_NAME+:: x
  # +ID_SORT_BY_TYPE+:: x
  # +ID_SORT_BY_SIZE+:: x
  # +ID_SORT_BY_TIME+:: x
  # +ID_SORT_BY_USER+:: x
  # +ID_SORT_BY_GROUP+:: x
  # +ID_SORT_REVERSE+:: x
  # +ID_DIRECTORY_UP+:: x
  # +ID_SET_PATTERN+:: x
  # +ID_SET_DIRECTORY+:: x
  # +ID_SHOW_HIDDEN+:: x
  # +ID_HIDE_HIDDEN+:: x
  # +ID_TOGGLE_HIDDEN+:: x
  # +ID_REFRESHTIMER+:: x
  # +ID_OPENTIMER+:: x
  #
  class FXFileList < FXIconList
  
    # Current file [String]
    attr_accessor :currentFile
    
    # Current directory [String]
    attr_accessor :directory
    
    # Wildcard matching pattern [String]
    attr_accessor :pattern
    
    # Wildcard matching mode [Integer]
    attr_accessor :matchMode
    
    # File associations [FXFileDict]
    attr_accessor :associations
    
    # Construct a file list
    def initialize(p, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theFileList
    end
  
    #
    # Scan the current directory and update the items if needed, or if _force_ is +true+.
    #
    def scan(force=true); end

    #
    # Return +true+ if item is a directory.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemDirectory?(index); end
  
    #
    # Return +true+ if item is a share.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemShare?(index); end

    #
    # Return +true+ if item is a file.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemFile?(index); end
  
    #
    # Return +true+ if item is executable.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemExecutable?(index); end
  
    #
    # Return name of item at index.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemFilename(index); end
  
    #
    # Return full pathname of item at index.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemPathname(index); end
    
    #
    # Return file association of item at index.
    # Raises IndexError if _index_ is out of bounds.
    #
    def itemAssoc(index); end
  
    # Return +true+ if showing hidden files.
    def hiddenFilesShown?; end
    
    # Show or hide hidden files.
    def hiddenFilesShown=(shown); end
    
    # Return +true+ if showing directories only.
    def onlyDirectoriesShown?; end
    
    # Show directories only.
    def onlyDirectoriesShown=(shown); end

    # Return +true+ if showing files only.
    def onlyFilesShown?; end
    
    # Show files only.
    def onlyFilesShown=(shown); end
  end
end

