require_relative 'prerequisites'

class InventoryTest < Test::Unit::TestCase

  def test_should_get_all_bulks_in_location
    inventory = Inventory.new(Location::W1)
    materials = inventory.material
    materials.each do |material|
      assert material.location == inventory.location
      bulks = material.bulk
      bulks.each do |bulk|
        assert bulk.location == material.location
      end
    end
  end

  def test_should_get_all_bulks_in_location_all_warehouses
    inventory = Inventory.new([Location::W1, Location::W2])
    materials = inventory.material
    materials.each do |material|
      assert material.location == inventory.location
      bulks = material.bulk
      bulks.each do |bulk|
        assert inventory.location.include? bulk.location
      end
    end
  end


  def test_get_all_materials_with_locations
    inventory = Inventory.new([Location::W1, Location::W2])
    materials = inventory.material
    materials.each do |material|
      assert material.location == inventory.location
    end
  end


  def test_get_single_material_with_locations
    m_id = 25
    inventory = Inventory.new(Location::W1)
    material = inventory.material m_id
    assert material.location == inventory.location
  end

end
