#!/usr/bin/env ruby

require 'fox12'
begin
  require 'net/http'
  require 'html-parser'
  require 'formatter'
rescue LoadError
  require 'fox12/missingdep'
  MSG = <<EOM
  Sorry, this example depends on the html-parser extension. Please
  check the Ruby Application Archives for an appropriate
  download site.
EOM
  missingDependency(MSG)
end

include Fox

# Simple HTMLParser subclass to look for the image URL
class MyHTMLParser < HTMLParser
  attr_reader :url
  def initialize
    super(NullFormatter.new)
    @url = nil
  end
  def do_img(attrs)
    src = nil
    alt = nil
    for attrname, value in attrs
      alt = value if attrname == 'alt'
      src = value if attrname == 'src'
    end
    @url = src.gsub(/\"/, "") if alt =~ /Today's Dilbert Comic/
  end
end

class DailyDilbert < FXMainWindow

  HOSTNAME = "www.dilbert.com"

  include Responder

  def initialize(app)
    # Invoke base class initialize first
    super(app, "Daily Dilbert Viewer", nil, nil, DECOR_ALL,
      0, 0, 850, 600, 0, 0)

    # Sunken border for image widget
    imagebox = FXHorizontalFrame.new(self,
      FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
  
    # Make image widget
    @imageview = FXImageView.new(imagebox, nil, nil, 0,
      LAYOUT_FILL_X|LAYOUT_FILL_Y|HSCROLLER_NEVER|VSCROLLER_NEVER)
      
    # Download the web page contents
    imageData = getImageData

    # Construct a GIF image and store it in the image viewer
    @imageview.image = FXGIFImage.new(getApp(), imageData)

    # Resize main window client area to fit image size
    resize(@imageview.contentWidth, @imageview.contentHeight)
  end
  
  def getImageURL
    imageURL = nil
    Net::HTTP.start(HOSTNAME, 80) { |http|
      response, = http.get('/')
      parser = MyHTMLParser.new
      parser.feed(response.body)
      parser.close
      imageURL = parser.url
    }
    imageURL
  end

  def getImageData
    response = nil
    Net::HTTP.start(HOSTNAME, 80) { |http|
      response, = http.get(getImageURL)
    }
    response.body
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
  end
end

if __FILE__ == $0
  # Make application
  application = FXApp.new("DailyDilbert", "FoxTest")

  # Make window
  window = DailyDilbert.new(application)

  # Create it
  application.create

  # Run
  application.run
end
