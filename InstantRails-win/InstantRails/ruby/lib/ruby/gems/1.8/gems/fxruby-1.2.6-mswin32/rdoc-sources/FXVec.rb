module Fox
  class FXVec
    #
    # Return an initialized FXVec instance.
    #
    def initialize(x=0.0, y=0.0, z=0.0); end
  
    #
    # Returns the element at _index_, where _index_ is 0, 1 or 2.
    # Raises IndexError if _index_ is out of range.
    #
    def [](index); end

    #
    # Set the element at _index_ to _value_ and return _value_.
    # Raises IndexError if _index_ is out of range.
    #
    def []=(index, value); end

    # Return +true+ if this vector is equal to _other_.
    def ==(other); end

    # Returns a new FXVec instance which is the negation of this one.
    def @-(); end

    #
    # Returns a new FXVec instance obtained by memberwise
    # addition of the _other_ FXVec instance with this
    # one.
    #
    def +(other); end

    #
    # Returns a new FXVec instance obtained by memberwise
    # subtraction of the _other_ FXVec instance from this
    # one.
    #
    def -(other); end

    #
    # Returns a new FXVec instance obtained by memberwise
    # multiplication of this vector's elements by the scalar
    # _n_.
    #
    def *(n); end

    #
    # Returns a new FXVec instance obtained by memberwise
    # division of this vector's elements by the scalar
    # _n_.
    # Raises ZeroDivisionError if _n_ is identically zero.
    #
    def /(n); end

    #
    # Returns the dot (scalar) product of this vector and _other_.
    #
    def dot(other); end

    #
    # Return the cross product of this vector and _other_.
    #
    def cross(other); end

    #
    # Return the length (magnitude) of this vector.
    #
    def len; end

    #
    # Return a new FXVec instance which is a normalized version
    # of this one.
    #
    def normalize; end

    #
    # Normalize this vector and return a reference to it.
    #
    def normalize!; end

    #
    # Return a new FXVec instance which is the lesser of this
    # vector and _other_.
    #
    def lo(other); end

    #
    # Return a new FXVec instance which is the greater of this
    # vector and _other_.
    #
    def hi(other); end

    # Return a new Array instance with this vector's elements as its members.
    def to_a; end
  end
end

