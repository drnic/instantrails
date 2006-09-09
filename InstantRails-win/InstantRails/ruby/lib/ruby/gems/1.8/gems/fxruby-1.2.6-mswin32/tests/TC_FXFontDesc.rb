require 'test/unit'

require 'fox12'

include Fox

class TC_FXFontDesc < Test::Unit::TestCase
  def setup
    @fontdesc = FXFontDesc.new
  end

  def test_face
    @fontdesc.face = "Times New Roman"
    assert_equal("Times New Roman", @fontdesc.face)
  end

  def test_size
    @fontdesc.size = 120
    assert_equal(120, @fontdesc.size)
  end

  def test_weight
    weights = [FONTWEIGHT_DONTCARE,
               FONTWEIGHT_THIN,
	       FONTWEIGHT_EXTRALIGHT,
	       FONTWEIGHT_LIGHT,
	       FONTWEIGHT_NORMAL,
	       FONTWEIGHT_REGULAR,
	       FONTWEIGHT_MEDIUM,
	       FONTWEIGHT_DEMIBOLD,
	       FONTWEIGHT_BOLD,
	       FONTWEIGHT_EXTRABOLD,
	       FONTWEIGHT_HEAVY,
	       FONTWEIGHT_BLACK]
    weights.each do |weight|
      @fontdesc.weight = weight
      assert_equal(weight, @fontdesc.weight)
    end
  end

  def test_slant
    slants = [FONTSLANT_DONTCARE,
              FONTSLANT_REGULAR,
	      FONTSLANT_ITALIC,
	      FONTSLANT_OBLIQUE,
	      FONTSLANT_REVERSE_ITALIC,
	      FONTSLANT_REVERSE_OBLIQUE]
    slants.each do |slant|
      @fontdesc.slant = slant
      assert_equal(slant, @fontdesc.slant)
    end
  end

  def test_encoding
  end

  def test_setwidth
  end

  def test_flags
  end
end
