module Fox
  #
  # Font style
  #
  class FXFontDesc

    # Typeface name, such as "helvetica" [String]
    attr_accessor :face
    
    # Font size in decipoints [Integer]
    attr_accessor :size
    
    # Font weight, such as +FONTWEIGHT_NORMAL+ or +FONTWEIGHT_BOLD+ [Integer].
    # See FXFont documentation for the complete list of font weight values.
    attr_accessor :weight
  
    # Font slant, such as +FONTSLANT_REGULAR+ or +FONTSLANT_ITALIC+ [Integer].
    # See FXFont documentation for the complete list of font slant values.
    attr_accessor :slant
    
    # Character set encoding, such as <tt>FONTENCODING_ISO_8859_1</tt> or <tt>FONTENCODING_LATIN1</tt> [Integer].
    # See FXFont documentation for the complete list of character set encoding values.
    attr_accessor :encoding
    
    # Font set width, such as +FONTSETWIDTH_CONDENSED+ or +FONTSETWIDTH_WIDE+ [Integer].
    # See FXFont documentation for the complete list of font set width values.
    attr_accessor :setwidth
    
    # Flags [Integer]
    attr_accessor :flags

    #
    # Constructor
    #
    def initialize ; end
  end

  #
  # Font class
  #
  # === Font style hints which influence the matcher
  #
  # <tt>FONTPITCH_DEFAULT</tt>::	Default pitch
  # <tt>FONTPITCH_FIXED</tt>::		Fixed pitch, mono-spaced
  # <tt>FONTPITCH_VARIABLE</tt>::	Variable pitch, proportional spacing
  # <tt>FONTHINT_DONTCARE</tt>::	Don't care which font
  # <tt>FONTHINT_DECORATIVE</tt>::	Fancy fonts
  # <tt>FONTHINT_MODERN</tt>::		Monospace typewriter font
  # <tt>FONTHINT_ROMAN</tt>::		Variable width times-like font, serif
  # <tt>FONTHINT_SCRIPT</tt>::		Script or cursive
  # <tt>FONTHINT_SWISS</tt>::		Helvetica/swiss type font, sans-serif
  # <tt>FONTHINT_SYSTEM</tt>::		System font
  # <tt>FONTHINT_X11</tt>::		X11 Font string
  # <tt>FONTHINT_SCALABLE</tt>::	Scalable fonts
  # <tt>FONTHINT_POLYMORPHIC</tt>::	Polymorphic fonts
  #
  # === Font slant
  #
  # +FONTSLANT_DONTCARE+::		Don't care about slant
  # +FONTSLANT_REGULAR+::		Regular straight up
  # +FONTSLANT_ITALIC+::		Italics
  # +FONTSLANT_OBLIQUE+::		Oblique slant
  # +FONTSLANT_REVERSE_ITALIC+::	Reversed italic
  # +FONTSLANT_REVERSE_OBLIQUE+::	Reversed oblique
  #
  # === Font character set encoding
  #
  # <tt>FONTENCODING_DEFAULT</tt>::			Don't care character encoding
  # <tt>FONTENCODING_ISO_8859_1</tt>::		West European (Latin1)
  # <tt>FONTENCODING_ISO_8859_2</tt>::		Central and East European (Latin2)
  # <tt>FONTENCODING_ISO_8859_3</tt>::		Esperanto (Latin3)
  # <tt>FONTENCODING_ISO_8859_4</tt>::		ISO-8859-4 character encoding
  # <tt>FONTENCODING_ISO_8859_5</tt>:: 		Cyrillic (almost obsolete)
  # <tt>FONTENCODING_ISO_8859_6</tt>::		Arabic
  # <tt>FONTENCODING_ISO_8859_7</tt>::		Greek
  # <tt>FONTENCODING_ISO_8859_8</tt>::		Hebrew
  # <tt>FONTENCODING_ISO_8859_9</tt>::		Turkish (Latin5)
  # <tt>FONTENCODING_ISO_8859_10</tt>::		ISO-8859-10 character encoding
  # <tt>FONTENCODING_ISO_8859_11</tt>::		Thai
  # <tt>FONTENCODING_ISO_8859_13</tt>::		Baltic
  # <tt>FONTENCODING_ISO_8859_14</tt>::		ISO-8859-14 character encoding
  # <tt>FONTENCODING_ISO_8859_15</tt>::		ISO-8859-15 character encoding
  # <tt>FONTENCODING_ISO_8859_16</tt>::		ISO-8859-16 character encoding
  # <tt>FONTENCODING_KOI8</tt>::		KOI-8 character encoding
  # <tt>FONTENCODING_KOI8_R</tt>::		Russian
  # <tt>FONTENCODING_KOI8_U</tt>::		Ukrainian
  # <tt>FONTENCODING_KOI8_UNIFIED</tt>::	x
  #
  # <tt>FONTENCODING_CP437</tt>::			IBM-PC code page
  # <tt>FONTENCODING_CP850</tt>::			IBM-PC Multilingual
  # <tt>FONTENCODING_CP851</tt>::			IBM-PC Greek
  # <tt>FONTENCODING_CP852</tt>::			IBM-PC Latin2
  # <tt>FONTENCODING_CP855</tt>::			IBM-PC Cyrillic
  # <tt>FONTENCODING_CP856</tt>::			IBM-PC Hebrew
  # <tt>FONTENCODING_CP857</tt>::			IBM-PC Turkish
  # <tt>FONTENCODING_CP860</tt>::			IBM-PC Portugese
  # <tt>FONTENCODING_CP861</tt>::			IBM-PC Iceland
  # <tt>FONTENCODING_CP862</tt>::			IBM-PC Israel
  # <tt>FONTENCODING_CP863</tt>::			IBM-PC Canadian/French
  # <tt>FONTENCODING_CP864</tt>::			IBM-PC Arabic
  # <tt>FONTENCODING_CP865</tt>::			IBM-PC Nordic
  # <tt>FONTENCODING_CP866</tt>::			IBM-PC Cyrillic #2
  # <tt>FONTENCODING_CP869</tt>::			IBM-PC Greek #2
  # <tt>FONTENCODING_CP870</tt>::			Latin-2 Multilingual
  #
  # <tt>FONTENCODING_CP1250</tt>::			Windows Central European
  # <tt>FONTENCODING_CP1251</tt>::			Windows Russian
  # <tt>FONTENCODING_CP1252</tt>::			Windows Latin1
  # <tt>FONTENCODING_CP1253</tt>::			Windows Greek
  # <tt>FONTENCODING_CP1254</tt>::			Windows Turkish
  # <tt>FONTENCODING_CP1255</tt>::			Windows Hebrew
  # <tt>FONTENCODING_CP1256</tt>::			Windows Arabic
  # <tt>FONTENCODING_CP1257</tt>::			Windows Baltic
  # <tt>FONTENCODING_CP1258</tt>::			Windows Vietnam
  # <tt>FONTENCODING_CP874</tt>::			Windows Thai
  #
  # <tt>FONTENCODING_LATIN1</tt>::		same as <tt>FONTENCODING_ISO_8859_1</tt>, Latin 1 (West European)
  # <tt>FONTENCODING_LATIN2</tt>::		same as <tt>FONTENCODING_ISO_8859_2</tt>, Latin 2 (East European) 
  # <tt>FONTENCODING_LATIN3</tt>::		same as <tt>FONTENCODING_ISO_8859_3</tt>, Latin 3 (South European) 
  # <tt>FONTENCODING_LATIN4</tt>::		same as <tt>FONTENCODING_ISO_8859_4</tt>, Latin 4 (North European) 
  # <tt>FONTENCODING_LATIN5</tt>::		same as <tt>FONTENCODING_ISO_8859_9</tt>, Latin 5 (Turkish) 
  # <tt>FONTENCODING_LATIN6</tt>::		same as <tt>FONTENCODING_ISO_8859_10</tt>, Latin 6 (Nordic) 
  # <tt>FONTENCODING_LATIN7</tt>::		same as <tt>FONTENCODING_ISO_8859_13</tt>, Latin 7 (Baltic Rim)
  # <tt>FONTENCODING_LATIN8</tt>::		same as <tt>FONTENCODING_ISO_8859_14</tt>, Latin 8 (Celtic)
  # <tt>FONTENCODING_LATIN9</tt>::		same as <tt>FONTENCODING_ISO_8859_15</tt>, Latin 9 (a.k.a. Latin 0)
  # <tt>FONTENCODING_LATIN10</tt>::		same as <tt>FONTENCODING_ISO_8859_16</tt>, Latin 10
  # <tt>FONTENCODING_USASCII</tt>::		same as <tt>FONTENCODING_ISO_8859_1</tt>, Latin 1
  # <tt>FONTENCODING_WESTEUROPE</tt>::		same as <tt>FONTENCODING_ISO_8859_1</tt>, Latin 1 (West European) 
  # <tt>FONTENCODING_EASTEUROPE</tt>::		same as <tt>FONTENCODING_ISO_8859_2</tt>, Latin 2 (East European) 
  # <tt>FONTENCODING_SOUTHEUROPE</tt>::		same as <tt>FONTENCODING_ISO_8859_3</tt>, Latin 3 (South European) 
  # <tt>FONTENCODING_NORTHEUROPE</tt>::		same as <tt>FONTENCODING_ISO_8859_4</tt>, Latin 4 (North European) 
  # <tt>FONTENCODING_CYRILLIC</tt>::		same as <tt>FONTENCODING_ISO_8859_5</tt>, Cyrillic
  # <tt>FONTENCODING_RUSSIAN</tt>::		same as <tt>FONTENCODING_KOI8</tt>, Cyrillic
  # <tt>FONTENCODING_ARABIC</tt>::		same as <tt>FONTENCODING_ISO_8859_6</tt>, Arabic
  # <tt>FONTENCODING_GREEK</tt>::		same as <tt>FONTENCODING_ISO_8859_7</tt>, Greek
  # <tt>FONTENCODING_HEBREW</tt>::		same as <tt>FONTENCODING_ISO_8859_8</tt>, Hebrew
  # <tt>FONTENCODING_TURKISH</tt>::		same as <tt>FONTENCODING_ISO_8859_9</tt>, Latin 5 (Turkish) 
  # <tt>FONTENCODING_NORDIC</tt>::		same as <tt>FONTENCODING_ISO_8859_10</tt>, Latin 6 (Nordic) 
  # <tt>FONTENCODING_THAI</tt>::		same as <tt>FONTENCODING_ISO_8859_11</tt>, Thai
  # <tt>FONTENCODING_BALTIC</tt>::		same as <tt>FONTENCODING_ISO_8859_13</tt>, Latin 7 (Baltic Rim)
  # <tt>FONTENCODING_CELTIC</tt>::		same as <tt>FONTENCODING_ISO_8859_14, Latin 8 (Celtic)
  #
  # === Font weight
  #
  # +FONTWEIGHT_DONTCARE+::	Don't care about weight
  # +FONTWEIGHT_THIN+::		Thin
  # +FONTWEIGHT_EXTRALIGHT+::	Extra light
  # +FONTWEIGHT_LIGHT+::	Light
  # +FONTWEIGHT_NORMAL+::	Normal or regular weight
  # +FONTWEIGHT_REGULAR+::	Normal or regular weight
  # +FONTWEIGHT_MEDIUM+::	Medium bold face
  # +FONTWEIGHT_DEMIBOLD+::	Demi bold face
  # +FONTWEIGHT_BOLD+::		Bold face
  # +FONTWEIGHT_EXTRABOLD+::	Extra
  # +FONTWEIGHT_HEAVY+::	Heavy
  # +FONTWEIGHT_BLACK+::	Black
  #
  # === Font relative setwidth
  #
  # +FONTSETWIDTH_DONTCARE+::		Don't care about set width
  # +FONTSETWIDTH_ULTRACONDENSED+::	Ultra condensed printing
  # +FONTSETWIDTH_EXTRACONDENSED+::	Extra condensed
  # +FONTSETWIDTH_CONDENSED+::		Condensed
  # +FONTSETWIDTH_NARROW+::		Narrow
  # +FONTSETWIDTH_COMPRESSED+::		Compressed
  # +FONTSETWIDTH_SEMICONDENSED+::	Semi-condensed
  # +FONTSETWIDTH_MEDIUM+::		Medium printing
  # +FONTSETWIDTH_NORMAL+::		Normal printing
  # +FONTSETWIDTH_REGULAR+::		Regular printing
  # +FONTSETWIDTH_SEMIEXPANDED+::	Semi expanded
  # +FONTSETWIDTH_EXPANDED+::		Expanded
  # +FONTSETWIDTH_WIDE+::		Wide
  # +FONTSETWIDTH_EXTRAEXPANDED+::	Extra expanded
  # +FONTSETWIDTH_ULTRAEXPANDED+::	Ultra expanded

  class FXFont < FXId

    # Font family name [String]
    attr_reader	:name

    # Actual font family name [String]
    attr_reader :actualName

    # Size in decipoints [Integer]
    attr_reader	:size
    
    # Actual size in deci-points [Integer]
    attr_reader :actualSize

    # Font weight [Integer]
    attr_reader	:weight
    
    # Actual font weight [Integer]
    attr_reader :actualWeight

    # Slant [Integer]
    attr_reader	:slant
    
    # Actual slant [Integer]
    attr_reader :actualSlant

    # Encoding [Integer]
    attr_reader	:encoding
    
    # Actual encoding [Integer]
    attr_reader :actualEncoding

    # Set width [Integer]
    attr_reader	:setWidth

    # Actual set width [Integer]
    attr_reader :actualSetWidth

    # Hints [Integer]
    attr_reader	:hints

    # Font description [FXFontDesc]
    attr_accessor :fontDesc

    # First character glyph in font [Integer]
    attr_reader	:minChar

    # Last character glyph in font [Integer]
    attr_reader	:maxChar

    # Width of widest character in font [Integer]
    attr_reader	:fontWidth

    # Height of tallest character in font [Integer]
    attr_reader	:fontHeight

    # Ascent from baseline [Integer]
    attr_reader	:fontAscent

    # Descent from baseline [Integer]
    attr_reader	:fontDescent

    # Font leading [Integer]
    attr_reader	:fontLeading

    # Font line spacing [Integer]
    attr_reader	:fontSpacing

    #
    # Return an FXFont instance, initialized from a font description.
    #
    # ==== Parameters:
    #
    # +a+::		an application instance [FXApp]
    # +fontDesc+::	a font description [FXFontDesc]
    #
    def initialize(a, fontDesc) # :yields: theFont
    end
  
    #
    # Return an FXFont instance initialized with the given face name, size in
    # points (pixels), weight, slant, character set encoding, set width, and hints.
    # The font name may be comprised of a family name and optional foundry name enclosed in 
    # square brackets, for example, "helvetica [bitstream]".
    #
    # ==== Parameters:
    #
    # +a+::			an application instance [FXApp]
    # +face+::		font face name [String]
    # +size+::		requested font size, in points [Integer]
    # +weight+::	requested font weight [Integer]
    # +encoding+::	requested font encoding [Integer]
    # +setWidth+::	requested font set width [Integer]
    # +hints+::		font construction hints for font matching algorithm [Integer]
    #
    def initialize(a, face, size, weight=FONTWEIGHT_NORMAL, slant=FONTSLANT_REGULAR, encoding=FONTENCODING_DEFAULT, setWidth=FONTSETWIDTH_DONTCARE, hints=0) # :yields: theFont
    end
  
    #
    #  Construct a font with given font description of the form:
    # 
    #      fontname [ "[" foundry "]" ] ["," size ["," weight ["," slant ["," setwidth ["," encoding ["," hints]]]]]]
    # 
    #  For example:
    # 
    #      "helvetica [bitstream],120,bold,i,normal,iso8859-1,0"
    # 
    #  Typically, at least the font name, and size must be given for
    #  normal font matching.  As a special case, raw X11 fonts can also be
    #  passed, for example:
    # 
    #      "9x15bold"
    # 
    #  Finally, an old FOX 1.0 style font string may be passed as well:
    # 
    #      "[helvetica] 90 700 1 1 0 0"
    # 
    def initialize(a, string) # :yields: theFont
    end

    #
    # Change the font to the specified font description string.
    # Returns +true+ on success.
    #
    def setFont(string); end

    #
    # Return the font description as a string suitable for
    # parsing with #setFont, see above.
    #
    def getFont(); end

    #
    # Return +true+ if font is monospaced.
    #
    def fontMono? ; end
  
    #
    # Return +true+ if font has glyph for _ch_. Here, _ch_ can either be an
    # ordinal value, e.g.
    #
    #     aFont.hasChar?(?a)
    #
    # or a string of length one (i.e. a single character), e.g.
    #
    #     aFont.hasChar?('a')
    #
    def hasChar?(ch) ; end

    #
    # Returns the left-side bearing (the distance from the origin to the leftmost pixel in the character) for _ch_.
    #
    def leftBearing(ch) ; end
  
    #
    # Returns the right-side bearing (the distance from the origin to the rightmost pixel in the character) for _ch_.
    #
    def rightBearing(ch) ; end
  
    #
    # Returns the width of given _text_ in this font.
    #
    def getTextWidth(text) ; end
  
    #
    # Returns the height of given _text_ in this font.
    #
    def getTextHeight(text) ; end
  
    #
    # List all fonts matching hints. Returns an array of FXFontDesc objects.
    #
    def FXFont.listFonts(face, weight=FONTWEIGHT_DONTCARE, slant=FONTSLANT_DONTCARE, setWidth=FONTSETWIDTH_DONTCARE, encoding=FONTENCODING_DEFAULT, hints=0)
    end
  end
end

