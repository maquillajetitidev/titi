require_relative 'prerequisites'

class MaterialBulkTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

  end


  def test_should_get_childrens_by_model_and_class
    material1 = Material[38]
    assert_equal(Array, material1.bulks(Location::W1).class)
    material2 = Material.new.get_by_id 38, Location::W1
    assert_equal(Array, material2.bulks(Location::W1).class)
  end

  def test_showuld_get_associations
    assert_equal(Array, Material.associations.class)
    assert_equal(Array, Bulk.associations.class)
  end

  def test_get_should_fetch_bulks
    mat = Material[38]
    bulks = mat.bulks Location::W1
    bulks.each do |bulk|
      assert_equal(Bulk, bulk.class)
    end
  end

  # def test_should_load_bulk_by_id
  #   bulk =  Bulk.first
  #   assert_equal(Bulk, bulk.class)
  #   mat = bulk.material
  #   assert_equal(Material, mat.class)
  # end

  def test_get_bulk_by_id_should_join_material_name
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      Bulk.new.create Material.select(:m_id).first[:m_id], 0.02, Location::W1
      first = Bulk.select(:b_id).first
      bulk = Bulk.new.get_by_id first.b_id

      assert(bulk[:m_name], "m_name wasn't joined")
    end
 end
end
