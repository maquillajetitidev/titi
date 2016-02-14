require_relative 'prerequisites'
require 'csv'

class TestMassiveUpdate < Test::Unit::TestCase
  def self.startup
    p "start"
    @@only_once = "only_once, can make several with different names"
  end

  def test_needing_startup_n_teardown
    CSV.foreach("../AccionMasivaIdeales2016.csv") do |row|
      p_id = row[0].to_i
      ideal = row[1]

      params = {"direct_ideal_stock" => ideal}
      product = Product[p_id]
      if product
        product = product.update_from_hash(params)
        product.validate
        if product.errors.count == 0  and product.valid?
          product.update_stocks.save
          if product.errors.count == 0  and product.valid?
            p "Updated pid #{p_id}"
          else
            p "Error updating pid #{p_id}: #{product.errors}"
          end
        else
          p "Error updating pid #{p_id}: #{product.errors}"
        end
      else
        p "Error updating pid #{p_id}: pid doesn't exist"
      end
    end
  end

  def teardown
  end

  def self.shutdown
  end
end
