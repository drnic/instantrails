module Fox
  #
  # FXHVec is a 3-D homogenous vector.
  #
  class FXHVec
    #
    # Returns a new, uninitialized FXHVec instance.
    #
    def initialize; end

    #
    # Returns a new FXHVec instance with contents initialized from _other_,
    # where _other_ is either an FXVec or FXHVec instance.
    #
    def initialize(other); end
  
    #
    # Returns a new FXHVec instance with initial components (_x_, _y_, _z_ and _w_).
    #
    def initialize(x, y, z, w=1.0); end
  
    #
    # Initialize with color
    #
    def initialize(color); end
  
    # Returns +true+ if this vector is equal to _other_.
    def ==(other); end
    
    # Returns the negation of this
    def -@(); end
    
    # Returns the <em>i</em>th element of this vector.
    def [](i); end
    
    # Set the <em>i</em>th element of this vector to _x_.
    def []=(i, x); end
    
    # Returns the sum of this vector and another vector
    def +(other); end
    
    # Returns the difference, this vector minus another vector
    def -(other); end
    
    # Returns the product of this vector and the scalar _x_.
    def *(x); end
    
    # Returns the quotient, this vector divided by the scalar _x_.
    def /(x); end

    # Returns the dot product of this vector and _other_.
    def dot(other); end
    
    # Returns the cross product of this vector and _other_.
    def cross(other); end
    
    # Returns the length of this vector
    def len; end

    # Returns the normalized version of this vector.
    def normalize; end

    #
    # Returns a new FXHVec, each of whose components is equal to the smaller
    # of this vector's and other's components, i.e.
    #
    #   self.lo(other) === FXHVec.new( [self[0], other[0]].min,
    #                                  [self[1], other[1]].min,
    #                                  [self[2], other[2]].min,
    #                                  [self[3], other[3]].min )
    #
    def lo(other); end

    #
    # Returns a new FXHVec, each of whose components is equal to the greater
    # of this vector's and other's components, i.e.
    #
    #   self.lo(other) === FXHVec.new( [self[0], other[0]].max,
    #                                  [self[1], other[1]].max,
    #                                  [self[2], other[2]].max,
    #                                  [self[3], other[3]].max )
    #
    def hi(other); end
    
    # Returns a stringified version of this vector
    def to_s; end

    # Convert to an array
    def to_a; end    
  end
end
