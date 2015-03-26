require_relative 'prerequisites'

class UtilsTest < Test::Unit::TestCase

  def test_convert
    start = 1000000.123456789123456789
    big = BigDecimal.new(start, 0)
    assert_equal start, big.to_f
  end

end