require_relative 'prerequisites'

class MaterialTest < Test::Unit::TestCase

  def setup
    @material_params = {"_method"=>"put", "m_id"=>"2", "c_id"=>"2", "m_name"=>"Liquido corporal azul", "m_qty"=>"6272", "m_price"=>"0.001", "splat"=>[], "captures"=>["2"], "id"=>"2"}

    @valid_material = Material.new
    @valid_material.m_id = 1
    @valid_material.c_id = 8
    @valid_material.m_name = "Liquido corporal negro"
    @valid_material.created_at = "2013-07-19 02:52:24 -0300"
  end

  def test_string_stripper
    m = Material.new
    m.m_name = "    Test name    "
    assert_equal("Test name", m.m_name)
  end

  def test_should_create_material_ignoring_extra_params
    m = Material.new
    m.m_id = 1
    assert(m.changed_columns.include?(:m_id))

    @material_params[:m_name] = "Liquido corporal azul 2"
    m.update_from_hash( @material_params )
    assert_equal(2, m[:c_id])
    assert_equal("Liquido corporal azul 2", m[:m_name])

    assert(m.changed_columns.include?(:c_id))
    assert(m.changed_columns.include?(:m_name))

    assert_equal(4, m.changed_columns.size, "There are #{m.changed_columns.size} changes and should have 4")
    puts "\n" + m.errors.to_s if m.errors.size != 0
  end

  def test_should_reject_nil_name
    m = Material.new
    m.m_id = 1
    m.m_name = nil
    assert_equal(false, m.valid?, "The name can't be nil")

    assert_equal( [R18n.t.errors.presence], m.errors[:Nombre])
    puts "\n" + m.errors.to_s if m.errors.size != 1
  end

  def test_should_reject_empty_name
    m = Material.new
    m.m_id = 1
    m.m_name = ""
    assert_equal(false, m.valid?, "The name can't be empty")
    assert_equal( [R18n.t.errors.presence], m.errors[:Nombre])
    puts "\n" + m.errors.to_s if m.errors.size != 1
end

  def test_should_accept_interger_id
    m = Material.new
    m.m_name = "test name"

    10.times do
      id = (rand()*1000).floor+1
      m.m_id = id
      assert_equal(id, m.m_id)
      assert(m.valid?, "The id must be a possitive integer #{id} #{id.class} given")
      puts "\n" + m.errors.to_s if m.errors.size != 0
    end
  end

  def test_should_reject_negative_id
    m = Material.new
    m.m_id = -1
    m.m_name = "test name"
    assert_equal(-1, m.m_id)
    assert_equal(false, m.valid?, "The id can't be negative")
    assert_equal( [R18n.t.errors.positive_feedback(-1)], m.errors[:m_id])
    puts "\n" + m.errors.to_s if m.errors.size != 1
  end

  def test_should_reject_zero_id
    m = Material.new
    m.m_id = 0
    m.m_name = "test name"
    assert_equal(0, m.m_id)
    assert_equal(false, m.valid?, "The id must be positive")
    assert_equal( [R18n.t.errors.positive_feedback(0)], m.errors[:m_id])
    puts "\n" + m.errors.to_s if m.errors.size != 1
  end

  def test_should_reject_nan_id
    m = Material.new
    m.m_name = "test name"
    m.m_id = "a"
    assert_equal(false, m.valid?, "The id must be numeric")
    puts "\n" + m.errors.to_s if m.errors.size != 1
  end

  def test_should_get_same_price_regardless_of_location
    mat1 = Material.new.get_by_id 31, Location::W1
    mat2 = Material.new.get_by_id 31, Location::W2
    mat3 = Material.new.get_by_id 31, Location::S2
    assert_equal mat1[:m_price], mat2[:m_price]
    assert_equal mat1[:m_price], mat3[:m_price]
  end

  def test_should_create_new_material
    mat = Material.filter(m_name: R18n.t.material.default_name).first
    unless mat.nil?
      mat.m_name = rand
      mat.save
    end
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      begin
        mat = Material.new.create_default
      rescue Sequel::UniqueConstraintViolation => e
        assert_equal "Mysql2::Error: Duplicate entry '! NUEVO MATERIAL' for key 'm_name'", e.message
        mat = Material.filter(m_name: R18n.t.material.default_name).first
        mat.m_name = rand
        mat.save
        mat = Material.new.create_default
      end
      assert_equal mat.class, Fixnum
    end
  end

  def test_if_m_price_is_updated_all_products_that_use_it_have_to_be_updated
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      material = Material[127]

      product = material.products[0]
      # materials = product.materials
      # materials.each { |m| p "#{m.m_id}: #{Utils::number_format m[:m_qty], 2} x #{m.m_price.to_s "F"} = #{(m[:m_qty]*m.m_price).to_s "F"}" }
      # p_mat = nil
      start_cost = product.materials_cost.dup

      material.m_price = material.m_price + 5
      material.save

      product = material.products[0]
      # materials = product.materials
      # materials.each { |m| p "#{m.m_id}: #{Utils::number_format m[:m_qty], 2} x #{m.m_price.to_s "F"} = #{(m[:m_qty]*m.m_price).to_s "F"}" }
      # p_mat = nil
      end_cost = product.materials_cost.dup
      assert_equal start_cost + 5*8, end_cost, "#{Utils::number_format start_cost + 5*8, 3} != #{Utils::number_format end_cost, 3}"
    end
  end

  def test_should_get_an_empty_material_for_invalid_sku
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      sku = rand
      material = Material.new.get_by_sku sku
      assert material.empty?
    end
  end

  def test_should_calculate_ideal_stock
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      material = Material[38]
      material.calculate_ideal_stock(debug: false)
      assert_equal BigDecimal.new(1520.2, 6).to_s("F"), material.m_ideal_stock.to_s("F") # TODO: don't asume an ideal
    end

  end

end
