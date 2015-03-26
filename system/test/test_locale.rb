require_relative 'prerequisites'

class ProductTest < Test::Unit::TestCase

  def test_number_format_1
    assert_equal "145.346.346.450,00", Utils::number_format(145346346450, 2)
  end

  def test_number_format_2
    assert_equal "145.346.346.450,000", Utils::number_format(145346346450, 3)
  end

  def test_number_format_3
    assert_equal "145.346.346.450", Utils::number_format(145346346450, 0)
  end

  def test_number_format_4
    assert_equal "125", Utils::number_format(125.255, 0)
  end

  def test_number_format_5
    assert_equal "125,3", Utils::number_format(125.255, 1)
  end

  def test_number_format_6
    assert_equal "125,26", Utils::number_format(125.255, 2)
  end
end
