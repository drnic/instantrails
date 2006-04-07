module Fox
  # OpenGL Viewer Viewport
  class FXViewport
    # Viewport width [Integer]
    attr_accessor :w
    
    # Viewport height
    attr_accessor :h
    
    # World left [Float]
    attr_accessor :left

    # World right [Float]
    attr_accessor :right

    # World bottom [Float]
    attr_accessor :bottom

    # World top [Float]
    attr_accessor :top

    # World hither [Float]
    attr_accessor :hither

    # World yon [Float]
    attr_accessor :yon
    
    # Returns an initialized FXViewport instance
    def initialize; end
  end

  # OpenGL Light Source
  class FXLight
    # Ambient light color [FXVec4f]
    attr_accessor :ambient

    # Diffuse light color [FXVec4f]
    attr_accessor :diffuse

    # Specular light color [FXVec4f]
    attr_accessor :specular

    # Light position [FXVec4f]
    attr_accessor :position

    # Spot direction [FXVec3f]
    attr_accessor :direction

    # Spotlight exponent [Float]
    attr_accessor :exponent

    # Spotlight cutoff angle [Float]
    attr_accessor :cutoff

    # Constant attenuation factor [Float]
    attr_accessor :c_attn

    # Linear attenuation factor [Float]
    attr_accessor :l_attn

    # Quadratic attenuation factor [Float]
    attr_accessor :q_attn
    
    # Returns an initialized FXLight instance
    def initialize; end
  end

  # OpenGL Material Description
  class FXMaterial
    # Ambient material color [FXVec4f]
    attr_accessor :ambient
    
    # Diffuse material color [FXVec4f]
    attr_accessor :diffuse
    
    # Specular material color [FXVec4f]
    attr_accessor :specular
    
    # Emissive material color [FXVec4f]
    attr_accessor :emission
    
    # Specular shininess [Float]
    attr_accessor :shininess
    
    # Returns an initialized FXMaterial instance
    def initialize; end
  end

  #
  # Canvas, an area drawn by another object
  #
  # === Events
  #
  # The following messages are sent by FXGLViewer to its message target:
  #
  # === FXGLViewer options
  #
  # +VIEWER_LIGHTING+::	Lighting is on
  # +VIEWER_FOG+::	Fog mode on
  # +VIEWER_DITHER+::	Dithering
  #
  # === Projection modes (class constants)
  #
  # +PARALLEL+::	Parallel projection
  # +PERSPECTIVE+::	Perspective projection
  #
  # === Message identifiers
  #
  # +ID_PERSPECTIVE+::		x
  # +ID_PARALLEL+::		x
  # +ID_FRONT+:: x
  # +ID_BACK+:: x
  # +ID_LEFT+:: x
  # +ID_RIGHT+:: x
  # +ID_TOP+:: x
  # +ID_BOTTOM+:: x
  # +ID_RESETVIEW+:: x
  # +ID_FITVIEW+:: x
  # +ID_TIPTIMER+:: x
  # +ID_TOP_COLOR+:: x
  # +ID_BOTTOM_COLOR+:: x
  # +ID_BACK_COLOR+:: x    
  # +ID_AMBIENT_COLOR+:: x
  # +ID_LIGHT_AMBIENT+:: x
  # +ID_LIGHT_DIFFUSE+:: x
  # +ID_LIGHT_SPECULAR+:: x
  # +ID_LIGHTING+:: x
  # +ID_TURBO+:: x
  # +ID_FOG+:: x
  # +ID_DITHER+:: x
  # +ID_SCALE_X+:: x
  # +ID_SCALE_Y+:: x
  # +ID_SCALE_Z+:: x
  # +ID_DIAL_X+:: x
  # +ID_DIAL_Y+:: x
  # +ID_DIAL_Z+:: x
  # +ID_ROLL+:: x
  # +ID_PITCH+:: x
  # +ID_YAW+:: x
  # +ID_FOV+:: x
  # +ID_ZOOM+:: x
  # +ID_CUT_SEL+:: x
  # +ID_COPY_SEL+:: x
  # +ID_PASTE_SEL+:: x
  # +ID_DELETE_SEL+:: x
  # +ID_PRINT_IMAGE+:: x
  # +ID_PRINT_VECTOR+:: x
  # +ID_LASSO_ZOOM+:: x
  # +ID_LASSO_SELECT+:: x
  #
  class FXGLViewer < FXGLCanvas
  
    # Size of pixel in world coordinates [Float]
    attr_reader :worldPix
    
    # Size of pixel in model coordinates [Float]
    attr_reader :modelPix
    
    # The viewport for this viewer [FXViewport]
    attr_reader :viewport
    
    # Default object material setting [FXMaterial]
    attr_accessor :material

    # Camera field of view angle (in degrees) [Float]
    attr_accessor :fieldOfView    

    # Camera zoom factor [Float]
    attr_accessor :zoom

    # Target point distance [Float]
    attr_accessor :distance
    
    # Current scaling factors [FXVec3f]
    attr_accessor :scale
    
    # Camera orientation [FXQuatf]
    attr_accessor :orientation
    
    # Object center [FXVec3f]
    attr_accessor :center
    
    # Eyesight vector [FXVec3f]
    attr_reader :eyeVector
    
    # Eye position [FXVec3f] 
    attr_reader :eyePosition
    
    # Status line help text [String]
    attr_accessor :helpText
    
    # Tool tip text [String]
    attr_accessor :tipText

    # The current transformation matrix [FXMat4f]
    attr_reader :transform
  
    # The inverse of the current transformation matrix [FXMat4f]
    attr_reader :invTransform
  
    # The current scene object [FXGLObject]
    attr_accessor :scene
  
    # The selection [FXGLObject]
    attr_accessor :selection
  
    # The projection mode (either +FXGLViewer::PERSPECTIVE+ or +FXGLViewer::PARALLEL+)
    attr_accessor :projection
    
    # Global ambient light color [FXMat4f]
    attr_accessor :ambientColor
  
    # The maximum hits, i.e. the maximum size of the pick buffer [Integer].
    # When less than or equal to zero, picking is essentially turned off.
    attr_accessor :maxHits
  
    # Set turbo mode [Boolean]
    attr_writer :turboMode
    
    # Light source settings [FXLight]
    attr_accessor :light
    
    # Returns the FXDragType for FXGLObject
    def FXGLViewer.objectType; end
  
    # Returns the drag type name
    def FXGLViewer.objectTypeName; end
  
    #
    # Construct GL viewer widget
    #
    def initialize(p, vis, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theGLViewer
    end
    
    #
    # Construct GL viewer widget sharing display list with another GL viewer
    #
    def initialize(p, vis, sharegroup, tgt=nil, sel=0, opts=0, x=0, y=0, w=0, h=0) # :yields: theGLViewer
    end
  
    # Return an array of all objects in the given rectangle
    def lasso(x1, y1, x2, y2); end
  
    # Change the model bounding box; this adjusts the viewer
    def setBounds(box); end
    
    # Fit viewer to the given bounding box
    def fitToBounds(box); end
    
    #
    # Translate eye-coordinate to screen coordinate.
    # Returns a 2-element array [sx, sy] containing the screen coordinate.
    #
    def eyeToScreen(e); end
  
    # Translate screen coordinate to eye coordinate at the given depth.
    def screenToEye(sx, sy, eyez=0.0); end
    
    # Translate screen coordinate to eye coordinate at the target point depth
    def screenToTarget(sx, sy); end
    
    # Translate world coordinate to eye coordinate
    def worldToEye(w); end
    
    # Translate world coordinate to eye coordinate depth
    def worldToEyeZ(w); end
    
    # Translate eye coordinate to eye coordinate
    def eyeToWorld(e); end 
    
    # Calculate world coordinate vector from screen movement
    def worldVector(fx, fy, tx, ty); end
    
    # Translate object center
    def translate(vec); end
    
    # Return boresight vector (an array of two arrays)
    def getBoreVector(sx, sy); end
    
    # Returns +true+ if the viewer is locked
    def locked?; end
    
    # Read the pixels off the screen as R,G,B tuples.
    def readPixels(x, y, w, h); end
    
    # Read the feedback buffer containing the current scene.
    def readFeedback(x, y, w, h); end
    
    #
    # When drawing a GL object, if doesTurbo? returns +true+, the object
    # may choose to perform a reduced complexity drawing as the user is
    # interactively manipulating; another update will be done later when
    # the full complexity drawing can be performed again.
    #
    def doesTurbo?; end
    
    # Returns +true+ if turbo mode is enabled
    def turboMode?; end

    #
    # Change top, bottom or both background colors.
    #
    def setBackgroundColor(clr, bottom=MAYBE); end

    # Return top or bottom window background color.
    def getBackgroundColor(bottom=false); end
  end
end

