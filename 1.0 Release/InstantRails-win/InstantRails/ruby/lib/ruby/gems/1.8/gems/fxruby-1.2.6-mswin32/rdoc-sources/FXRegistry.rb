module Fox
  #
  # The registry maintains a database of persistent settings for an application,
  # or suite of applications.
  #
  class FXRegistry < FXSettings

    # Application key [String]
    attr_reader	:appKey
    
    # Vendor key [String]
    attr_reader	:vendorKey
    
    # Use file-based registry instead of Windows Registry [Boolean]
    attr_writer	:asciiMode

    #
    # Construct registry object; _appKey_ and _vendorKey_ must be string constants.
    # Regular applications SHOULD set a vendor key!
    #
    def initialize(appKey="", vendorKey="") ; end
    
    #
    # Read registry.
    #
    def read; end
    
    #
    # Write registry.
    #
    def write; end

    #
    # Return +true+ if we're using a file-based registry mechanism instead of the Windows Registry
    # (only relevant on Windows systems).
    #
    def asciiMode?; end
  end
end
