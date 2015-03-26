require_relative 'prerequisites'

class LocationTest < Test::Unit::TestCase

  def test_warehouses
    t = Location.new.warehouses
    assert t.count > 0
    t.each { |tr| assert_equal tr.keys, [:name, :translation, :level] }
  end

  def test_stores
    t = Location.new.stores
    assert t.count > 0
    t.each { |tr| assert_equal tr.keys, [:name, :translation, :level] }
  end

  def test_valid
    assert Location.new.valid? "STORE_1"
    assert Location.new.valid? "WAREHOUSE_1"
    assert Location.new.valid? "WAREHOUSE_2"
  end

  def test_invalid
    assert_false Location.new.valid? "STORE_2"
    assert_false Location.new.valid? "STORE_11"
    assert_false Location.new.valid? "invalid"
  end

end
