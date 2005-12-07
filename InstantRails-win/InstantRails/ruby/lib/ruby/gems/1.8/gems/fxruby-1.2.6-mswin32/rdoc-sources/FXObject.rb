module Fox
  #
  # Base class for all FOX objects.
  #
  class FXObject
    #
    # Handle a message sent from _sender_, with given _selector_
    # and message _data_.
    #
    def handle(sender, selector, data); end

    #
    # Save object to stream.
    #
    def save(stream) ; end

    #
    # Load object from _stream_.
    #
    def load(stream) ; end
  end
end
