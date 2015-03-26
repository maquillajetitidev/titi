# coding: utf-8
require_relative 'prerequisites'

class SupplyTest < Test::Unit::TestCase


  def test_s1_whole_ideal_should_not_be_modified_on_save
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      s = Supply.new.get 135
      s.s1_whole_ideal = 5
      s.save
      s = Supply.new.get 135
      assert_equal 5, s.s1_whole_ideal, "Erroneous s1_whole_ideal"
    end
  end

  def test_new_supply_should_be_empty
    supply = Supply.new
    assert supply.empty?
  end

  def test_get_nil_should_fill_defaults
    supply = Supply.new.get nil
    Supply.db_schema.map { |column| assert supply.respond_to? column[0].to_sym }
    Supply.default_values.each { |key, val| assert_equal supply.send(key), val }
    assert supply.p_id.nil?
    assert supply.updated_at.nil?
  end

  def test_init_should_fill_defaults
    supply = Supply.new.init
    Supply.db_schema.map { |column| assert supply.respond_to? column[0].to_sym }
    Supply.default_values.each { |key, val| assert_equal supply.send(key), val }
    assert supply.p_id.nil?
    assert supply.updated_at.nil?
  end

  def test_should_not_save_empty_supply
    assert_raise Sequel::DatabaseError do
      supply = Supply.new.init.save
    end
  end

  def test_get_should_fill_missing_p_id
    product = Product.last
    supply = Supply.new.get product.p_id
    assert_equal product.p_id, supply.p_id
  end

  def test_get_product_from_supply
    supply = Supply[Product.last.p_id]
    if supply.nil?
      ap "No supply record for #{Product.last.p_id}"
    else
      product = supply.product
      assert_equal supply.p_id, product.p_id
    end
  end

  def test_supply_entries_should_equal_products_entries
    assert_equal Product.count, Supply.count
  end

  def test_every_product_should_have_s1_whole_ideal
    products = Product.new.get_all.where(archived: 0).where(end_of_life: 0).where(non_saleable: 0).where(on_request: 0).where(end_of_life: 0).all
    products.each do |p|
      ap "#{p.p_name} (#{p.p_id}) has an ideal of zero" unless p.supply.s1_whole_ideal > 0
    end
  end

  def test_supply_check_values
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      p = Product.new.get 135
      p.update_stocks
      p.update_ideal_stock

      "p_id"

      "s1_whole"
      "s1_whole_en_route"
      assert_equal p.supply.s1_whole + p.supply.s1_whole_en_route, p.supply.s1_whole_future, "s1_whole_future"
      "s1_whole_ideal"
      assert_equal (p.supply.s1_whole - p.supply.s1_whole_ideal).to_s("F"), p.supply.s1_whole_deviation.to_s("F"), "s1_whole_deviation"
      "s1_part"
      "s1_part_en_route"
      assert_equal p.supply.s1_part + p.supply.s1_part_en_route, p.supply.s1_part_future, "s1_part_future"
      "s1_part_ideal"
      assert_equal (p.supply.s1_part - p.supply.s1_part_ideal).to_s("F"), p.supply.s1_part_deviation.to_s("F"), "s1_part_deviation"
      assert_equal (p.supply.s1_whole + p.supply.s1_part).to_s("F"), p.supply.s1.to_s("F"), "s1"

      assert_equal p.supply.s1_whole_en_route + p.supply.s1_part_en_route,  p.supply.s1_en_route, "s1_en_route"
      assert_equal p.supply.s1 + p.supply.s1_en_route,  p.supply.s1_future, "s1_future"
      assert_equal (p.supply.s1_whole_ideal + p.supply.s1_part_ideal).to_s("F"), p.supply.s1_ideal.to_s("F"), "s1_ideal"
      # assert_equal (p.supply.s1 - p.supply.s1_ideal).to_s("F"), p.supply.s1_deviation.to_s("F"), "s1_deviation"

      "s2_whole"
      "s2_whole_en_route"
      assert_equal p.supply.s2_whole + p.supply.s2_whole_en_route, p.supply.s2_whole_future, "s2_whole_future"
      "s2_whole_ideal"
      assert_equal (p.supply.s2_whole - p.supply.s2_whole_ideal).to_s("F"), p.supply.s2_whole_deviation.to_s("F"), "s2_whole_deviation"
      "s2_part"
      "s2_part_en_route"
      assert_equal p.supply.s2_part + p.supply.s2_part_en_route, p.supply.s2_part_future, "s2_part_future"
      "s2_part_ideal"
      assert_equal (p.supply.s2_part - p.supply.s2_part_ideal).to_s("F"), p.supply.s2_part_deviation.to_s("F"), "s2_part_deviation"
      assert_equal (p.supply.s2_whole_future + p.supply.s2_part_future).to_s("F"), p.supply.s2.to_s("F"), "s2"
      assert_equal p.supply.s2_whole_en_route + p.supply.s2_part_en_route,  p.supply.s2_en_route, "s2_en_route"
      assert_equal p.supply.s2 + p.supply.s2_en_route,  p.supply.s2_future, "s2_future"
      assert_equal (p.supply.s2_whole_ideal + p.supply.s2_part_ideal).to_s("F"), p.supply.s2_ideal.to_s("F"), "s2_ideal"
      assert_equal (p.supply.s2 - p.supply.s2_ideal).to_s("F"), p.supply.s2_deviation.to_s("F"), "s2_deviation"

      assert_equal p.supply.s1_whole + p.supply.s2_whole, p.supply.stores_whole, "stores_whole"
      assert_equal p.supply.s1_whole_en_route + p.supply.s2_whole_en_route, p.supply.stores_whole_en_route, "stores_whole_en_route"
      assert_equal p.supply.stores_whole + p.supply.stores_whole_en_route, p.supply.stores_whole_future, "stores_whole_future"
      assert_equal p.supply.s1_whole_ideal + p.supply.s2_whole_ideal, p.supply.stores_whole_ideal, "stores_whole_ideal"
      # assert_equal (p.supply.stores_whole - p.supply.stores_whole_ideal).to_s("F"), p.supply.stores_whole_deviation.to_s("F"), "stores_whole_deviation"
      assert_equal p.supply.s1_part + p.supply.s2_part, p.supply.stores_part, "stores_part"
      assert_equal p.supply.s1_part_en_route + p.supply.s2_part_en_route, p.supply.stores_part_en_route, "stores_part_en_route"
      assert_equal p.supply.stores_part + p.supply.stores_part_en_route, p.supply.stores_part_future, "stores_part_future"
      assert_equal (p.supply.s1_part_ideal + p.supply.s2_part_ideal).to_s("F"), p.supply.stores_part_ideal.to_s("F"), "stores_part_ideal"
      # assert_equal (p.supply.stores_part - p.supply.stores_part_ideal).to_s("F"), p.supply.stores_part_deviation.to_s("F"), "stores_part_deviation"
      assert_equal p.supply.s1 + p.supply.s2, p.supply.stores, "stores"
      assert_equal p.supply.stores_whole_en_route + p.supply.stores_part_en_route, p.supply.stores_en_route, "stores_en_route"
      assert_equal p.supply.stores + p.supply.stores_en_route, p.supply.stores_future, "stores_future"
      assert_equal (p.supply.s1_ideal + p.supply.s2_ideal).to_s("F"), p.supply.stores_ideal.to_s("F"), "stores_ideal"
      # assert_equal (p.supply.stores - p.supply.stores_ideal).to_s("F"), p.supply.stores_deviation.to_s("F"), "stores_deviation"

#################################

      "w1_whole"
      "w1_whole_en_route"
      assert_equal p.supply.w1_whole + p.supply.w1_whole_en_route, p.supply.w1_whole_future, "w1_whole_future"
      "w1_whole_ideal"
      # assert_equal (p.supply.w1_whole - p.supply.w1_whole_ideal).to_s("F"), p.supply.w1_whole_deviation.to_s("F"), "w1_whole_deviation"
      "w1_part"
      "w1_part_en_route"
      assert_equal p.supply.w1_part + p.supply.w1_part_en_route, p.supply.w1_part_future, "w1_part_future"
      "w1_part_ideal"
      # assert_equal (p.supply.w1_part - p.supply.w1_part_ideal).to_s("F"), p.supply.w1_part_deviation.to_s("F"), "w1_part_deviation"
      assert_equal (p.supply.w1_whole_future + p.supply.w1_part_future).to_s("F"), p.supply.w1.to_s("F"), "w1"
      assert_equal p.supply.w1_whole_en_route + p.supply.w1_part_en_route,  p.supply.w1_en_route, "w1_en_route"
      assert_equal p.supply.w1 + p.supply.w1_en_route,  p.supply.w1_future, "w1_future"
      assert_equal (p.supply.w1_whole_ideal + p.supply.w1_part_ideal).to_s("F"), p.supply.w1_ideal.to_s("F"), "w1_ideal"
      # assert_equal (p.supply.w1 - p.supply.w1_ideal).to_s("F"), p.supply.w1_deviation.to_s("F"), "w1_deviation"

      "w2_whole"
      "w2_whole_en_route"
      assert_equal p.supply.w2_whole + p.supply.w2_whole_en_route, p.supply.w2_whole_future, "w2_whole_future"
      "w2_whole_ideal"
      assert_equal (p.supply.w2_whole - p.supply.w2_whole_ideal).to_s("F"), p.supply.w2_whole_deviation.to_s("F"), "w2_whole_deviation"
      "w2_part"
      "w2_part_en_route"
      assert_equal p.supply.w2_part + p.supply.w2_part_en_route, p.supply.w2_part_future, "w2_part_future"
      "w2_part_ideal"
      assert_equal (p.supply.w2_part - p.supply.w2_part_ideal).to_s("F"), p.supply.w2_part_deviation.to_s("F"), "w2_part_deviation"
      assert_equal (p.supply.w2_whole_future + p.supply.w2_part_future).to_s("F"), p.supply.w2.to_s("F"), "w2"
      assert_equal p.supply.w2_whole_en_route + p.supply.w2_part_en_route,  p.supply.w2_en_route, "w2_en_route"
      assert_equal p.supply.w2 + p.supply.w2_en_route,  p.supply.w2_future, "w2_future"
      assert_equal (p.supply.w2_whole_ideal + p.supply.w2_part_ideal).to_s("F"), p.supply.w2_ideal.to_s("F"), "w2_ideal"
      # assert_equal (p.supply.w2 - p.supply.w2_ideal).to_s("F"), p.supply.w2_deviation.to_s("F"), "w2_deviation"

      assert_equal p.supply.w1_whole + p.supply.w2_whole, p.supply.warehouses_whole, "warehouses_whole"
      assert_equal p.supply.w1_whole_en_route + p.supply.w2_whole_en_route, p.supply.warehouses_whole_en_route, "warehouses_whole_en_route"
      assert_equal p.supply.warehouses_whole + p.supply.warehouses_whole_en_route, p.supply.warehouses_whole_future, "warehouses_whole_future"
      "warehouses_whole_ideal"
      # assert_equal (p.supply.warehouses_whole - p.supply.warehouses_whole_ideal).to_s("F"), p.supply.warehouses_whole_deviation.to_s("F"), "warehouses_whole_deviation"
      assert_equal p.supply.w1_part + p.supply.w2_part, p.supply.warehouses_part, "warehouses_part"
      assert_equal p.supply.w1_part_en_route + p.supply.w2_part_en_route, p.supply.warehouses_part_en_route, "warehouses_part_en_route"
      assert_equal p.supply.warehouses_part + p.supply.warehouses_part_en_route, p.supply.warehouses_part_future, "warehouses_part_future"
      "warehouses_part_ideal"
      # assert_equal (p.supply.warehouses_part - p.supply.warehouses_part_ideal).to_s("F"), p.supply.warehouses_part_deviation.to_s("F"), "warehouses_part_deviation"
      assert_equal p.supply.w1 + p.supply.w2, p.supply.warehouses, "warehouses"
      assert_equal p.supply.warehouses_whole_en_route + p.supply.warehouses_part_en_route, p.supply.warehouses_en_route, "warehouses_en_route"
      assert_equal p.supply.warehouses + p.supply.warehouses_en_route, p.supply.warehouses_future, "warehouses_future"
      assert_equal (p.supply.w1_ideal + p.supply.w2_ideal).to_s("F"), p.supply.warehouses_ideal.to_s("F"), "warehouses_ideal"
      # assert_equal (p.supply.warehouses - p.supply.warehouses_ideal).to_s("F"), p.supply.warehouses_deviation.to_s("F"), "warehouses_deviation"

#################################
      assert_equal p.supply.stores_whole + p.supply.warehouses_whole, p.supply.global_whole, "global_whole"
      assert_equal p.supply.stores_whole_en_route + p.supply.warehouses_whole_en_route, p.supply.global_whole_en_route, "global_whole_en_route"
      assert_equal p.supply.stores_whole_future + p.supply.warehouses_whole_future, p.supply.global_whole_future, "global_whole_future"
      assert_equal p.supply.stores_whole_ideal + p.supply.warehouses_whole_ideal, p.supply.global_whole_ideal, "global_whole_ideal"
      "global_whole_deviation"
      assert_equal p.supply.stores_part + p.supply.warehouses_part, p.supply.global_part, "global_part"
      assert_equal (p.supply.stores_part_en_route + p.supply.warehouses_part_en_route).to_s("F"), p.supply.global_part_en_route.to_s("F"), "global_part_en_route"
      assert_equal p.supply.stores_part_future + p.supply.warehouses_part_future, p.supply.global_part_future, "global_part_future"
      assert_equal p.supply.stores_part_ideal + p.supply.warehouses_part_ideal, p.supply.global_part_ideal, "global_part_ideal"
      "global_part_deviation"
      assert_equal p.supply.stores + p.supply.warehouses, p.supply.global, "global"
      assert_equal p.supply.stores_en_route + p.supply.warehouses_en_route, p.supply.global_en_route, "global_en_route"
      assert_equal p.supply.stores_future + p.supply.warehouses_future, p.supply.global_future, "global_future"
      assert_equal (p.supply.stores_ideal + p.supply.warehouses_ideal).to_s("F"), p.supply.global_ideal.to_s("F"), "global_ideal"
      "global_deviation"


      assert_equal p.supply.warehouses_whole + p.supply.stores_whole, p.supply.global_whole, "global_whole"
      assert_equal p.supply.warehouses_whole_en_route + p.supply.stores_whole_en_route, p.supply.global_whole_en_route, "global_whole_en_route"
      assert_equal p.supply.global_whole + p.supply.global_whole_en_route, p.supply.global_whole_future, "global_whole_future"
      assert_equal p.supply.warehouses_whole_ideal + p.supply.stores_whole_ideal, p.supply.global_whole_ideal, "global_whole_ideal"
      "global_whole_deviation"
      assert_equal p.supply.warehouses_part + p.supply.stores_part, p.supply.global_part, "global_part"
      assert_equal p.supply.warehouses_part_en_route + p.supply.stores_part_en_route, p.supply.global_part_en_route, "global_part_en_route"
      assert_equal p.supply.global_part + p.supply.global_part_en_route, p.supply.global_part_future, "global_part_future"
      assert_equal p.supply.warehouses_part_ideal + p.supply.stores_part_ideal, p.supply.global_part_ideal, "global_part_ideal"
      "global_part_deviation"
      assert_equal p.supply.warehouses + p.supply.stores, p.supply.global, "global"
      assert_equal p.supply.warehouses_en_route + p.supply.stores_en_route, p.supply.global_en_route, "global_en_route"
      assert_equal p.supply.global + p.supply.global_en_route, p.supply.global_future, "global_future"
      assert_equal p.supply.warehouses_ideal + p.supply.stores_ideal, p.supply.global_ideal, "global_ideal"
      "global_deviation"

    end
  end

  def test_ideal_stock
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      p = Product.new.get 135
      assemblies = p.assemblies
      assemblies.map do |assy|
        assy.supply.s1_whole_ideal = 5
        assy.supply.s1_part_ideal = 5


        assy.supply.recalculate_ideals

        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.s1_whole_ideal.to_s("F"), "s1_whole_ideal"
        assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.s2_whole_ideal.to_s("F"), "s2_whole_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.stores_whole_ideal.to_s("F"), "stores_whole_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.s1_part_ideal.to_s("F"), "s1_part_ideal"
        assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.s2_part_ideal.to_s("F"), "s2_part_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.stores_part_ideal.to_s("F"), "stores_part_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.stores_whole_ideal.to_s("F"), "stores_whole_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.stores_part_ideal.to_s("F"), "stores_part_ideal"
        assert_equal BigDecimal.new(10, 2).to_s("F"), assy.supply.stores_ideal.to_s("F"), "stores_ideal"

        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.w1_whole_ideal.to_s("F"), "w1_whole_ideal"
        assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.w2_whole_ideal.to_s("F"), "w2_whole_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.warehouses_whole_ideal.to_s("F"), "warehouses_whole_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.w1_part_ideal.to_s("F"), "w1_part_ideal"
        assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.w2_part_ideal.to_s("F"), "w2_part_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.warehouses_part_ideal.to_s("F"), "warehouses_part_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.warehouses_whole_ideal.to_s("F"), "warehouses_whole_ideal"
        assert_equal BigDecimal.new(5, 2).to_s("F"), assy.supply.warehouses_part_ideal.to_s("F"), "warehouses_part_ideal"
        assert_equal BigDecimal.new(10, 2).to_s("F"), assy.supply.warehouses_ideal.to_s("F"), "warehouses_ideal"

        assert_equal BigDecimal.new(10, 2).to_s("F"), assy.supply.global_whole_ideal.to_s("F"), "global_whole_ideal"
        assert_equal BigDecimal.new(10, 2).to_s("F"), assy.supply.global_part_ideal.to_s("F"), "global_part_ideal"
        assert_equal BigDecimal.new(20, 2).to_s("F"), assy.supply.global_ideal.to_s("F"), "global_ideal"

      end

    end
  end

  def test_deviations_stores_1
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.s1_part = 20
      assy.supply.s1_whole = 60
      assy.supply.s1_part_ideal = 50
      assy.supply.s1_whole_ideal = 50

      assy.supply.recalculate_ideals
      # p "s1_part_deviation"
      # ap assy.supply.s1_part_deviation
      # p "s1_whole_deviation "
      # ap assy.supply.s1_whole_deviation
      assert_equal BigDecimal.new(-30, 2).to_s("F"), assy.supply.s1_deviation.to_s("F"), "s1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.s2_deviation.to_s("F"), "s2_deviation"
    end
  end

  def test_deviations_stores_2
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.s1_part = 60
      assy.supply.s1_whole = 20
      assy.supply.s1_part_ideal = 50
      assy.supply.s1_whole_ideal = 50

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(-30, 2).to_s("F"), assy.supply.s1_deviation.to_s("F"), "s1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.s2_deviation.to_s("F"), "s2_deviation"
    end
  end

  def test_deviations_stores_3
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.s1_part = 60
      assy.supply.s1_whole = 60
      assy.supply.s1_part_ideal = 50
      assy.supply.s1_whole_ideal = 50

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(10, 2).to_s("F"), assy.supply.s1_deviation.to_s("F"), "s1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.s2_deviation.to_s("F"), "s2_deviation"
    end
  end

  def test_deviations_stores_4
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.s1_part = 40
      assy.supply.s1_whole = 40
      assy.supply.s1_part_ideal = 50
      assy.supply.s1_whole_ideal = 50

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(-20, 2).to_s("F"), assy.supply.s1_deviation.to_s("F"), "s1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.s2_deviation.to_s("F"), "s2_deviation"
    end
  end

  def test_deviations_warehouses_1
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.w1_part = 20
      assy.supply.w1_whole = 60
      assy.supply.w1_part_ideal = 50
      assy.supply.w1_whole_ideal = 50
      assy.supply.w2_part = 0
      assy.supply.w2_whole = 0
      assy.supply.w2 = 0

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(-30, 2).to_s("F"), assy.supply.w1_deviation.to_s("F"), "w1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.w2_deviation.to_s("F"), "w2_deviation"
    end
  end

  def test_deviations_warehouses_2
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.w1_part = 60
      assy.supply.w1_whole = 20
      assy.supply.w1_part_ideal = 50
      assy.supply.w1_whole_ideal = 50
      assy.supply.w2_part = 0
      assy.supply.w2_whole = 0
      assy.supply.w2 = 0

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(-30, 2).to_s("F"), assy.supply.w1_deviation.to_s("F"), "w1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.w2_deviation.to_s("F"), "w2_deviation"
    end
  end

  def test_deviations_warehouses_3
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.w1_part = 60
      assy.supply.w1_whole = 60
      assy.supply.w1_part_ideal = 50
      assy.supply.w1_whole_ideal = 50
      assy.supply.w2_part = 0
      assy.supply.w2_whole = 0
      assy.supply.w2 = 0

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(10, 2).to_s("F"), assy.supply.w1_deviation.to_s("F"), "w1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.w2_deviation.to_s("F"), "w2_deviation"
    end
  end

  def test_deviations_warehouses_4
    p = Product.new.get 135
    assemblies = p.assemblies
    assemblies.map do |assy|
      assy.supply.w1_part = 40
      assy.supply.w1_whole = 40
      assy.supply.w1_part_ideal = 50
      assy.supply.w1_whole_ideal = 50
      assy.supply.w2_part = 0
      assy.supply.w2_whole = 0
      assy.supply.w2 = 0

      assy.supply.recalculate_ideals
      assert_equal BigDecimal.new(-20, 2).to_s("F"), assy.supply.w1_deviation.to_s("F"), "w1_deviation"
      assert_equal BigDecimal.new(0, 2).to_s("F"), assy.supply.w2_deviation.to_s("F"), "w2_deviation"
    end
  end


  def test_should_calculate_ideal_stock
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      product = Product.new.get 135
      product.update_ideal_stock
      calculated_parts_ideal = BigDecimal.new(0)
      product.assemblies.each do |assembly|
        assembly.update_ideal_stock
        calculated_parts_ideal += assembly[:part_qty] * assembly.supply.global_whole_ideal unless assembly.archived
      end
      assert_equal calculated_parts_ideal.round(2).to_s("F"), product.supply.global_part_ideal.round(2).to_s("F"), "global_part_ideal"
      assert_equal (calculated_parts_ideal + product.supply.global_whole_ideal).round(2).to_s("F"), product.supply.global_ideal.round(2).to_s("F"), "global_ideal"
      assert_equal 0, (product.supply.global_ideal - calculated_parts_ideal - product.supply.global_whole_ideal).round, "Erroneous ideal stock relation"
    end
  end

end
