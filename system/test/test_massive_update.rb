require_relative 'prerequisites'
require 'csv'

class TestMassiveUpdate < Test::Unit::TestCase
  def self.startup
    p "start"
    @@only_once = "only_once, can make several with different names"
  end

  def test_needing_startup_n_teardown
    CSV.foreach("../AccionMasivaIdeales2018.csv") do |row|
      p_id = row[0].to_i
      ideal = row[1]

      params = {"direct_ideal_stock" => ideal}
      product = Product[p_id]

      if product
      	tercerized = product.tercerized
        product = product.update_from_hash(params)
        # esta negrada la tengo que hacer porque el update_from_hash 
        # piso tercerized a false, tiene un alto bug esa mierda
        # se detecto con este flag pero puede haber otro kilombo mas en ese
        # update_from_hash, hay que hacerle verdadero testing en el proximo
        # update masivo de ideales, que esperemos nunca se de ya que
        # va a estar el nuevo sitio
        product.tercerized = tercerized

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
