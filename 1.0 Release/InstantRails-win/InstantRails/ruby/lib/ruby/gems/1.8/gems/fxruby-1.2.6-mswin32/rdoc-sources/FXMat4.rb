module Fox
  #
  # FXHMat is a 3-D homogeneous matrix.
  #
  class FXHMat
    #
    # Returns a new FXHMat instance with uninitialized
    # elements.
    #
    def initialize; end
    
    # 
    # Returns a new FXHMat instance with all elements
    # initialized to _w_.
    #
    def initialize(w); end
    
    #
    # Returns a new FXHMat instance with elements initialized
    # by the supplied values (e.g. _a12_ is the initial value
    # for the second row and third column).
    #
    def initialize(a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23, a30, a31, a32, a33); end
    
    #
    # Returns a new FXHMat instance with each row initialized
    # to the values in each of the input vectors (_a_, _b_, _c_ and _d_).
    #
    def initialize(a, b, c, d); end
    
    #
    # Returns a new FXHMat instance initialized from the contents
    # of _otherMatrix_.
    #
    def initialize(otherMatrix); end

    # Returns sum of this matrix and _other_.
    def +(other); end
  
    # Returns _self_ - _other_.
    def -(other); end
  
    #
    # Returns the product of this matrix and _x_, where
    # _x_ is either another matrix or a scalar.
    #
    def *(x); end
    
    #
    # Returns the result of performing an elementwise division
    # of this matrix by _x_.
    #
    def /(x); end
  
    # Returns the <em>i</em>th row of this matrix (an FXHVec)
    def [](i); end
  
    # Returns the determinant of this matrix
    def det(); end
  
    # Returns the transpose of this matrix
    def transpose; end
  
    # Returns the inversion of this matrix
    def invert; end
  
    # Returns the stringified version of this matrix
    def to_s; end
  
    # Set to identity matrix and return _self_.
    def eye(); end
  
    # Set to orthographic projection for specified bounding box and return _self_.
    def ortho(left, right, bottom, top, hither, yon); end
    
    # Set to perspective projection for specified bounding box and return _self_.
    def frustum(left, right, bottom, top, hither, yon); end
  
    # Multiply by left-hand matrix and return _self_.
    def left(); end
  
    # Pre-multiply this matrix by the rotation about unit-quaternion _q_ and return _self_.
    def rot(q); end
  
    #
    # Pre-multiply this matrix by the rotation (_c_, _s_) about _axis_ and
    # return _self_. Here, _axis_ is a FXVec instance, _c_ is the cosine of
    # the angle of rotation and _s_ is the sine of the angle of rotation.
    #
    def rot(axis, c, s); end
  
    #
    # Pre-multiply by a rotation of _phi_ radians about _axis_ (an FXVec
    # instance) and and return _self_.
    #
    def rot(axis, phi); end
  
    #
    # Pre-multiply by rotation about the x-axis and return _self_.
    # Here, _c_ is the cosine of the angle of rotation and _s_
    # is the sine of the angle of rotation.
    #
    def xrot(c, s); end
    
    #
    # Pre-multiply by a rotation of _phi_ radians about the x-axis and return
    # _self_.
    #
    def xrot(phi); end
  
    #
    # Pre-multiply by rotation about the y-axis and return _self_.
    # Here, _c_ is the cosine of the angle of rotation and _s_
    # is the sine of the angle of rotation.
    #
    def yrot(c, s); end
    
    #
    # Pre-multiply by a rotation of _phi_ radians about the y-axis and return
    # _self_.
    #
    def yrot(phi); end
  
    #
    # Pre-multiply by rotation about the z-axis and return _self_.
    # Here, _c_ is the cosine of the angle of rotation and _s_
    # is the sine of the angle of rotation.
    #
    def zrot(c, s); end
    
    #
    # Pre-multiply by a rotation of _phi_ radians about the z-axis and return
    # _self_.
    #
    def zrot(phi); end
  
    #
    # Look at and return _self_.
    #
    def look(eye, cntr, vup); end
  
    #
    # Pre-multiply this matrix by the translation tranformation matrix
    # T(_tx_, _ty_, _tz_) and return _self_.
    #
    def trans(tx, ty, tz); end
    
    #
    # Pre-multiply this matrix by the translation tranformation matrix
    # T(_vec_[0], _vec_[1], _vec_[2]) and return _self_.
    #
    def trans(vec); end
  
    #
    # Pre-multiply by the scaling tranformation matrix S(_sx_, _sy_, _sz_)
    # and return _self_.
    #
    def scale(sx, sy, sz); end
    
    #
    # Scale by _s_ and return _self_.
    #
    def scale(s); end

    #
    # Pre-multiply by the scaling tranformation matrix S(_sx_, _sy_, _sz_)
    # and return _self_.
    #
    def scale(vec); end
  end
end
