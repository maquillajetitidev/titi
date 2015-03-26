require_relative 'prerequisites'

class ProductCategoryTest < Test::Unit::TestCase

  def setup
    @valid = Product.new.get_rand
  end

  def test_get_category
    cat = @valid.category
    assert cat.is_a? Category
    assert cat.respond_to? :c_id
    assert cat.respond_to? :c_name
  end

end


class ItemCategoryTest < Test::Unit::TestCase

  def setup
    @valid = Item.new.get_rand
  end

  def test_get_category
    cat = @valid.category
    assert cat.is_a? Category
    assert cat.respond_to? :c_id
    assert cat.respond_to? :c_name
  end

end
