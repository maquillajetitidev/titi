require_relative 'prerequisites'

class BulkTest < Test::Unit::TestCase

  def setup
    @material_params = {"_method"=>"put", "m_id"=>"2", "m_name"=>"Liquido corporal azul", "m_qty"=>"6272", "m_price"=>"0.001", "splat"=>[], "captures"=>["2"], "id"=>"2"}
    @invalid_id = "13.07.16.a5c67927"
    @bulk_params = {"_method"=>"put", "b_qty"=>"511", "b_price"=>"0.1", "b_status"=>"NEW", "splat"=>[], "captures"=>["329.b15753444"], "id"=>"329.b15753444", "m_id"=>1}

    @valid_bulk = Bulk.new
    @valid_bulk.b_qty =  BigDecimal.new  1
    @valid_bulk.b_price =  BigDecimal.new  1
    @valid_bulk.b_status = Bulk::NEW
    @valid_bulk.b_id = "123.b12345678"
    @valid_bulk.m_id = 1
  end

  def test_should_use_binary_search
    b_id = Bulk.first.b_id
    assert_false Bulk[b_id].empty?
    assert Bulk[b_id.to_i].nil?
  end

  def test_should_create_bulk_ignoring_extra_params
    b = Bulk.new
    b.update_from_hash( @bulk_params )
    assert(b.changed_columns.include?(:b_status), "b_status not updated")
    assert(b.changed_columns.include?(:b_qty), "m_qty not updated")
    assert_equal(2, b.changed_columns.size, "There are #{b.changed_columns.size} changes and should have 3")
    puts "\n" + b.errors.to_s if b.errors.size != 0
  end

  def test_bulk_should_reject_malformed_id
    b = Bulk.new
    b.update_from_hash( @bulk_params )
    b.m_id = 1
    b.b_id = @invalid_id
    assert(!b.valid?, "Shouldn't allow malformed id")
    assert_equal( ["Malformed id 13.07.16.a5c67927"], b.errors[:b_id])
    puts "\n" + b.errors.to_s if b.errors.size != 1
  end

  def test_bulk_should_reject_negative_qty
    b = @valid_bulk
    b.b_qty = -1
    assert_false b.valid?, "Shouldn't allow negative qty"
    puts "\n" + b.errors.to_s if b.errors.size != 1
  end

  def test_bulk_update_should_reject_nil_params
    b = @valid_bulk
    assert_raise ArgumentError do
      b.update_from_hash( nil )
    end
  end


end
