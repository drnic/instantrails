module Fox
  #
  # Scrolling menu pane.
  #
  class FXScrollPane < FXMenuPane

    # Index of top-most menu item [Integer]
    attr_accessor :topItem

    #
    # Return an initialized FXScrollPane instance.
    #
    # ==== Parameters:
    #
    # +owner+::	owner window for this menu pane [FXWindow]
    # +nvis+::	maximum number of visible items [Integer]
    # +opts+::	options [Integer]
    #
    def initialize(owner, nvis, opts=0) # :yields: theScrollPane
    end
  end
end

