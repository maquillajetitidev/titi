require_relative 'prerequisites'

class ProductTest < Test::Unit::TestCase

  def setup
    @valid_product = Product.where(parts_cost: 0, materials_cost: 0).first
    @valid_product.sale_cost = BigDecimal.new 10
    @valid_product.price = BigDecimal.new 20
    assert_equal @valid_product.price, BigDecimal.new(20), "Shit"
    @valid_product.exact_price = BigDecimal.new 19.54, 5
    @valid_product.recalculate_markups
    @valid_product.p_name = "ProductTest @valid_product"
  end

  def test_get_rand
    p = Product.new.get_rand
    assert_equal(Product, p.class)
  end

  def test_should_get_items
    p = Product[5]
    items = p.items
    items.each { |i| assert_equal(Item, i.class) }
  end

  def test_should_get_parts_with_id_and_qty
    p = Product[192]
    p.parts.each do |part|
      assert(part[:part_id])
      assert(part[:part_qty])
    end
  end

  def test_should_get_prod_materials_with_qty
    p = Product[194]
    p.materials.each do |mat|
      assert(mat[:m_qty])
    end
  end

  def test_should_add_label_to_product
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      label = get_printed_label
      product = Product.new.get_rand
      before = product.items.count
      assigned_msg = product.add_item(label, nil)
      item = Item[label.i_id]
      assert_equal(Item::ASSIGNED, item.i_status)
      assert_equal(product.p_id, item.p_id)
      assert_equal(product.price, item.i_price)
      assert_equal(product.price_pro, item.i_price_pro)
      assert_equal assigned_msg, R18n::t.label.assigned(item.i_id, product.p_name)
      after = product.items.count
      assert_equal before+1, after
    end
  end

  def test_should_remove_label_from_product
    product = Product.new.get_rand
    step1, step2, step3 = 0
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      label = get_printed_label
      step1 = product.items.count
      product.add_item label, nil
      step2 = product.items.count
      product.items.each do |item|
        product.remove_item item
      end
    end
    step3 = product.items.count
    assert_equal step1+1, step2
    assert_equal step2-1, step3
    assert_equal step1, step3
  end

  def test_should_get_parts_cost
    product = Product[193]
    cost = 0
    product.parts.map { |part| cost += part.materials_cost }
    assert_equal product.parts_cost, cost
  end

  def test_cost_should_be_the_sum_of_parts_plus_materials
    product = Product.new.get 193
    message = "product 193 sale_cost (#{product.sale_cost.to_s("F")}) should equal (product.materials_cost + product.parts_cost).round(2) (#{(product.materials_cost + product.parts_cost).round(2).to_s("F")})"
    assert_equal product.sale_cost.round(2), (product.materials_cost + product.parts_cost).round(2), message

    product = Product.new.get 2
    message = "product 2 sale_cost (#{product.sale_cost.to_s("F")}) should equal (product.materials_cost + product.parts_cost).round(2) (#{(product.materials_cost + product.parts_cost).round(2).to_s("F")})"
    assert_equal product.sale_cost.round(2), (product.materials_cost + product.parts_cost).round(2), message
  end

  def test_check_cost
    Product.all.each do |product|
      if product.exact_price < product.sale_cost
        p "Inconsistent product (price lower than cost) #{product.p_id}: #{product.exact_price.to_s "F"} < #{product.sale_cost.to_s "F"}"
        product.exact_price = product.sale_cost * 2
        product.save
      end
      if product.price*1.1 < product.exact_price
        p "Inconsistent product (price lower than exact_price) #{product.p_id}: #{(product.price*1.1).to_s "F"} < #{product.exact_price.to_s "F"}"
        product.price = product.price = product.exact_price
        product.save
      end
    end
  end

  def test_mod_price_should_ignore_zero
    expected_price = @valid_product.price
    @valid_product.price_mod 0
    assert_equal expected_price, @valid_product.price
  end

  def test_mod_price_should_ignore_one
    expected_price = @valid_product.exact_price.round(1)
    @valid_product.price_mod 1
    assert_equal expected_price.to_s("F"), @valid_product.price.to_s("F")
  end

  def test_mod_price_should_include_mila_marzi
    @valid_product.br_name = "Mila Marzi"
    mod = 1.1
    expected = 21.5 # 21.494
    expected_price = BigDecimal.new("#{expected}", 2)
    @valid_product.price_mod mod
    assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
  end

  def test_mod_price_should_include_archived
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.1
      expected = 21.5 # 21.494
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_0_89
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 0.89
      expected = 17.4 # 19.54 * 0.89 = 17.39
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_0_01
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 0.01
      expected = 0.2 # 0.2
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_1_0009
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.0009
      expected = 19.6 # 19.54 * 1.009 = 19.5575
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_1_1
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.1
      expected = 21.5 # 21.494
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_1_01
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.01
      expected = 19.7 # 19.7354
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_1_11
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.11
      expected = 21.7 # 19.54 * 1.11 = 21.68
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_1_13
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.13
      expected = 22.1 # 19.54 * 1.13 = 22.08
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_1_5
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 1.5
      expected = 29.3 # 19.54 * 1.5 = 29.31
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_5_123
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = 5.123
      expected = 100 # 19.54 * 5.123 = 100.10342
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_1_0009
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "1,0009"
      expected = 19.6 # 19.54 * 1.009 = 19.5575
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_1_1
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "1,1"
      expected = 21.5 # 21.494
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_1_01
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "1,01"
      expected = 19.7 # 19.7354
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_1_11
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "1,11"
      expected = 21.7 # 19.54 * 1.11 = 21.68
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_1_13
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "1,13"
      expected = 22.1 # 19.54 * 1.13 = 22.08
      expected_price = BigDecimal.new("#{expected}", 1)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_1_5
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "1,5"
      expected = 29.3 # 19.54 * 1.5 = 29.31
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_0_89
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "0.89"
      expected = 17.4 # 19.54 * 0.89 = 17.39
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_0_01
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "0,01"
      expected = 0.2 # 0.2
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_mod_price_with_comma_5_123
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      mod = "5,123"
      expected = 100 # 19.54 * 5.123 = 100.10342
      expected_price = BigDecimal.new("#{expected}", 2)
      @valid_product.price_mod mod
      assert_equal expected_price.to_s("F") , @valid_product.price.to_s("F")
    end
  end

  def test_should_update_from_hash
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      hash = {direct_ideal_stock: "90,00", indirect_ideal_stock: "90,00", stock_warehouse_1: "100,00", buy_cost: "1,0", sale_cost: "1,0"}
      @valid_product.update_from_hash hash
      assert_equal BigDecimal.new(180).to_s("F"), @valid_product.ideal_stock.to_s("F"), "Erroneous ideal_stock 1"
      assert_equal 100, @valid_product.stock_warehouse_1
    end
  end

  def test_save_when_updated_from_hash
    DB.transaction(rollback: :always, isolation: :uncommitted) do

      hash = {direct_ideal_stock: "5", indirect_ideal_stock: "5", ideal_markup: "100.00", real_markup: "90.50", buy_cost: "1,0", sale_cost: "1,0", price: "100", exact_price: "99,95", brand: JSON.generate({br_id: "1", br_name: "test"}) }
      p_id = Product.new.create_default
      product = Product.new.get p_id
      product.update_from_hash hash
      product.save
      product = Product.new.get product.p_id
      assert_equal BigDecimal.new(10).to_s("F"), product.ideal_stock.to_s("F"), "Erroneous ideal_stock 2"
      assert_equal 100, product.ideal_markup, "Erroneous ideal_markup"
    end
  end

  def test_should_duplicate_products
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      src = Product[193]
      src.save
      dst = src.duplicate
      copied_columns = Product::ATTRIBUTES - Product::EXCLUDED_ATTRIBUTES_IN_DUPLICATION
      copied_columns.each do |col|
        message = src[col].class == BigDecimal ? "(#{col}): src[#{col}]:  #{src[col].to_s("F")}, dst[#{col}]: #{dst[col].to_s("F")}" : "(#{col}): src[col]:  #{src[col]}, dst[col]: #{dst[col]}"
        assert_equal src[col], dst[col], message
      end
      dst_id =  dst[:p_id]
      src = Product[193].parts
      dst = Product[dst_id].parts
      assert_equal src.size, dst.size
      for i in 0...src.size
        assert_equal src[i][:p_id], dst[i][:p_id]
        assert_equal src[i][:part_qty], dst[i][:part_qty]
      end
      src = Product[193].materials
      dst = Product[dst_id].materials
      assert_equal src.size, dst.size
      for i in 0...src.size
        assert_equal src[i][:m_id], dst[i][:m_id]
        assert_equal src[i][:m_qty], dst[i][:m_qty]
      end
    end
  end

  def test_should_add_material_to_product
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      material = Material.new.get_rand
      material[:m_qty] = 5
      prev_count = @valid_product.materials.count
      @valid_product.add_material material
      new_count = @valid_product.materials.count
      assert_equal prev_count + 1, new_count
    end
  end

  def test_should_not_allow_to_add_material_with_zero_qty_to_product
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      material = Material.new.get_rand
      material[:m_qty] = 0
      prev_count = @valid_product.materials.count
      @valid_product.add_material material
      new_count = @valid_product.materials.count
      assert_equal prev_count , new_count
      assert_equal 1, @valid_product.errors.count
    end
  end

  def test_should_update_material_qty
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      material = Material.new.get_rand
      material[:m_qty] = 5
      count1 = @valid_product.materials.count
      new_material = @valid_product.add_material material
      count2 = @valid_product.materials.count
      assert_equal count1 + 1, count2, "Error adding"
      assert_equal BigDecimal.new(5), new_material[:m_qty], "Error adding"

      material[:m_qty] = -5
      updated_material = @valid_product.update_material material
      count3 = @valid_product.materials.count
      assert_equal count2 , count3, "Error updating negative"
      assert_equal 1, @valid_product.errors.count, "Error updating negative"
      assert_equal BigDecimal.new(5), updated_material[:m_qty], "Error updating negative"

      material[:m_qty] = 3
      updated_material = @valid_product.update_material material
      count4 = @valid_product.materials.count
      assert_equal count3, count4, "Error updating"
      assert_equal 1, @valid_product.errors.count, "Error updating"
      assert_equal BigDecimal.new(3), updated_material[:m_qty], "Error updating"

      material[:m_qty] = 0
      updated_material = @valid_product.update_material material
      count5 = @valid_product.materials.count
      assert_equal count4 - 1, count5, "Error removing"
      assert_equal 1, @valid_product.errors.count, "Error removing"
    end
  end

  def test_should_add_part_to_product
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      part = Product.new.get_rand
      part[:part_qty] = 5
      prev_count = @valid_product.parts.count
      @valid_product.add_part part
      new_count = @valid_product.parts.count
      assert_equal prev_count + 1, new_count
    end
  end

  def test_should_not_allow_to_add_part_with_zero_qty_to_product
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      part = Product.new.get_rand
      part[:part_qty] = 0
      prev_count = @valid_product.parts.count
      @valid_product.add_part part
      new_count = @valid_product.parts.count
      assert_equal prev_count , new_count
      assert_equal 1, @valid_product.errors.count
    end
  end

  def test_should_update_part_qty
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      part = Product.new.get_rand
      part[:part_qty] = 5
      count1 = @valid_product.parts.count
      new_part = @valid_product.add_part part
      count2 = @valid_product.parts.count
      assert_equal count1 + 1, count2, "Error adding"
      assert_equal BigDecimal.new(5), new_part[:part_qty], "Error adding"

      part[:part_qty] = -5
      updated_part = @valid_product.update_part part
      count3 = @valid_product.parts.count
      assert_equal count2 , count3, "Error updating negative"
      assert_equal 1, @valid_product.errors.count, "Error updating negative"
      assert_equal BigDecimal.new(5), updated_part[:part_qty], "Error updating negative"

      part[:part_qty] = 3
      updated_part = @valid_product.update_part part
      count4 = @valid_product.parts.count
      assert_equal count3, count4, "Error updating"
      assert_equal 1, @valid_product.errors.count, "Error updating"
      assert_equal BigDecimal.new(3), updated_part[:part_qty], "Error updating"

      part[:part_qty] = 0
      updated_part = @valid_product.update_part part
      count5 = @valid_product.parts.count
      assert_equal count4 - 1, count5, "Error removing"
      assert_equal 1, @valid_product.errors.count, "Error removing"
    end
  end

  def test_should_get_product_by_sku
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      sku = rand
      @valid_product.sku = sku
      orig = @valid_product.save
      product = Product.new.get_by_sku sku
      assert_equal orig.p_id, product.p_id
    end
  end

  def test_should_get_an_empty_product_for_invalid_sku
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      sku = rand
      product = Product.new.get_by_sku sku
      assert product.empty?
    end
  end

  def test_should_clean_given_sku
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      sku = "    a e i \n \r \t o     u    "
      @valid_product.sku = sku
      assert_equal "a e i o u", @valid_product.sku
    end
  end

  def test_should_return_nil_if_empty_sku
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      sku = ""
      @valid_product.sku = sku
      assert_equal nil, @valid_product.sku
    end
  end

  def test_should_get_materials_cost
    product = Product[2]
    expected_cost =  BigDecimal.new(0, 3)
    product.materials.map do |material|
      expected_cost +=  material[:m_qty] * material[:m_price]
      # ap "#{material[:m_qty].to_s("F")} * #{material[:m_price].to_s("F")}"
    end
    # 1 * 3.355 + 1 * 0.88 + 100 * 0.304 = 34.635
    assert_equal expected_cost.round(3).to_s("F"), product.materials_cost.to_s("F")
  end

  def test_should_round_price_to_1_decimal_if_under_100
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      @valid_product.price = 6.5555
      assert_equal BigDecimal.new(6.5, 1), @valid_product.price, "Erroneous price"
    end
  end

  def test_should_get_empty_product_when_id_is_invalid
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      product = Product.new.get("invalid")
      assert product.empty?
    end
  end

  def test_should_ignore_non_present_values
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      product = Product.where(parts_cost: 0, materials_cost: 0).first
      cost = BigDecimal.new(10, 2)
      product.buy_cost = cost
      product.sale_cost = cost
      hash = {}
      product.update_from_hash hash
      assert_equal cost.to_s("F"), product.sale_cost.to_s("F"), "non_present_values"
      assert_equal cost.to_s("F"), product.buy_cost.to_s("F"), "non_present_values"
    end
  end


  def test_should_reject_invalid_strings_in_numerical_values
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      product = Product.where(parts_cost: 0, materials_cost: 0).first
      cost = BigDecimal.new(10, 2)
      product.buy_cost = cost
      product.sale_cost = cost
      hash = {sale_cost: "a"}
      product.update_from_hash hash
      assert_equal cost.to_s("F"), product.sale_cost.to_s("F"), "invalid_strings_in_numerical_values"
    end
  end

  def test_should_reject_badly_formatted_numbers
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      product = Product.where(parts_cost: 0, materials_cost: 0).first
      cost = BigDecimal.new(10, 2)
      product.buy_cost = cost
      product.sale_cost = cost
      hash = {sale_cost: "1..1"}
      product.update_from_hash hash
      assert_equal cost.to_s("F"), product.sale_cost.to_s("F"), "badly_formatted_numbers"
    end
  end

  def test_should_reject_nil_numerical_values
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      product = Product.new.get_rand
      cost = BigDecimal.new(10, 2)
      zero = BigDecimal.new(0, 2)
      product.parts_cost = zero
      product.materials_cost = zero
      product.buy_cost = cost
      product.sale_cost = cost
      hash = {sale_cost: nil, buy_cost: nil}
      product.update_from_hash hash
      assert_equal cost.to_s("F"), product.sale_cost.to_s("F"), "sale_cost"
      assert_equal cost.to_s("F"), product.buy_cost.to_s("F"), "buy_cost"
    end
  end

  def test_should_set_ideal_to_zero_when_marked_as_on_request
    product = Product.where(on_request: false).first
    product.set_sale_mode :on_request
    product.supply.each { |k, v| assert_equal BigDecimal.new(0, 2), v, k if k.to_s.include? "ideal" }
  end

end
