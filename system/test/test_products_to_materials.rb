require_relative 'prerequisites'

class ProductMaterialTest < Test::Unit::TestCase

  def test_should_get_products_with_category
    material = Material.new.get_by_id 20, Location::W1
    products = material.products
    products.each { |product| assert_equal("Crema demaquillante", product.values[:c_name]) }
  end
end
