require_relative 'prerequisites'

class DistributorTest < Test::Unit::TestCase

  def setup
    @valid_product = Product.new.get_rand
    @valid_product.sale_cost = BigDecimal.new 10
    @valid_product.price = BigDecimal.new 20
    assert_equal @valid_product.price, BigDecimal.new(20), "Shit"
    @valid_product.exact_price = BigDecimal.new 19.54, 5
    @valid_product.recalculate_markups
    @valid_product.p_name = "ProductTest @valid_product"
  end

  def test_should_get_distributors
    p_mila = Product[941]
    count = p_mila.distributors.all.count
    assert_equal 1, count, "la cantidad de distrobuidores es #{count}"

    d_mila = Distributor[15]

    assert d_mila.products.count > 1, "La cantidad de productos es #{d_mila.products.count}"
  end

  def test_should_add_product_to_distributor
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      distributor = Distributor.new.get_rand
      old_count = distributor.products.count

      product = Product
                    .select_group(*Product::COLUMNS)
                    .join(:products_to_distributors, products__p_id: :products_to_distributors__p_id)
                    .join(:distributors, products_to_distributors__d_id: :distributors__d_id)
                    .left_join(:categories, [:c_id])
                    .left_join(:brands, [:br_id])
                    .where(Sequel.~(distributors__d_id: distributor.d_id))
                    .last

      distributor.add_product product
      new_count = distributor.products.count
      assert_equal old_count+1 , new_count
    end
  end

  def test_should_add_multiple_distributors_to_product_and_get_them_ordered_by_date_added
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      distributor1 = Distributor.first
      distributor2 = Distributor.last

      # sanity check
      distributor1.remove_product @valid_product
      distributor2.remove_product @valid_product

      distributor1.add_product @valid_product
      distributor2.add_product @valid_product
      assert_equal  distributor2.d_id, @valid_product.distributors.all.last.d_id
    end
  end

end
