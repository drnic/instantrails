module Fox
  #
  # Registers stuff to know about the extension
  #
  class FXFileAssoc
    # Command to execute [String]
    attr_accessor :command
    
    # Full extension name [String]
    attr_accessor :extension
    
    # Mime type name [String]
    attr_accessor :mimetype
    
    # Big normal icon [FXIcon]
    attr_accessor :bigicon
    
    # Big open icon [FXIcon]
    attr_accessor :bigiconopen
    
    # Mini normal icon [FXIcon]
    attr_accessor :miniicon
    
    # Mini open icon [FXIcon]
    attr_accessor :miniiconopen
    
    # Registered drag type [FXDragType]
    attr_accessor :dragtype
    
    # Flags [Integer]
    attr_accessor :flags
    
    # Returns an initialized FXFileAssoc instance
    def initialize; end
  end

  #
  # An FXIconDict instance stores a mapping between the file names
  # for icon files and FXIcon instances built from those icon files.
  # Unlike a regular "dictionary" or hash-like object, the FXIconDict
  # constructs and owns its own data (the FXIcon instances).
  #
  # If no icon path is specified at construction time, a default icon path
  # of "~/.foxicons:/usr/local/share/icons:/usr/share/icons" is used.
  #
  # The particular subclass of FXIcon used for a given icon file is
  # deduced from the file extension.
  #
  class FXIconDict < FXDict
  
    # Associated application [FXApp]
    attr_reader :app
    
    # Current icon search path [String]
    attr_accessor :iconPath
    
    # Return the default icon search path
    def FXIconDict.defaultIconPath; end
  
    #
    # Return an initialized FXIconDict instance.
    #
    #
    # ==== Parameters:
    #
    # +a+::	the application [FXApp]
    # +p+::
    #   the search path used to find named icons [String]. If no path is specified,
    #   the default icon path is used.
    #
    def initialize(a, p=defaultIconPath); end
  
    #
    # Insert unique icon loaded from filename into dictionary;
    # returns a reference to the icon.
    #
    def insert(filename); end
  
    #
    # Remove icon from dictionary; returns a reference to the icon.
    #
    def remove(name); end
  
    # Find icon by name
    def find(name); end
  end
  


  #
  # File association dictionary
  #
  class FXFileDict < FXDict
  
    # Application [FXApp]
    attr_reader :app
    
    # Current icon search path [String]
    attr_accessor :iconPath
    
    # Return the registry key used to find fallback executable icons.
    def FXFileDict.defaultExecBinding(); end
  
    # Return the registry key used to find fallback directory icons.
    def FXFileDict.defaultDirBinding(); end

    # Return the registry key used to find fallback document icons.
    def FXFileDict.defaultFileBinding(); end
  
    #
    # Construct a dictionary mapping file-extension to file associations,
    # using the application registry settings as a source for the bindings.
    #
    def initialize(a); end
  
    #
    # Construct a dictionary mapping file-extension to file associations,
    # using the specified settings database as a source for the bindings.
    #
    # ==== Parameters:
    #
    # +a+:	Application [FXApp]
    # +db+::	Settings database [FXSettings]
    #
    def initialize(a, db); end
      return new FXRbFileDict(a,db);
      }
    }
  
    #
    # Replace file association for the specified extension;
    # returns a reference to the file association.
    #
    # ==== Parameters:
    #
    # +ext+::	Extension [String]
    # +str+::	String [String]
    #
    def replace(ext, str); end
  
    #
    # Remove file association for the specified extension
    # and return a reference to it.
    #
    def remove(ext); end
  
    #
    # Find file association for the specified extension already in dictionary
    # and return a reference to it.
    #
    def find(ext); end
  
    #
    # Find file association from registry for the specified key.
    #
    def associate(key); end

    # Returns a reference to the FXFileAssoc instance...
    def findFileBinding(pathname); end

    # Returns a reference to the FXFileAssoc instance...
    def findDirBinding(pathname); end

    # Returns a reference to the FXFileAssoc instance...
    def findExecBinding(pathname); end
  end
end

