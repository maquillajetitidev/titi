 require_relative 'prerequisites'

class LineItemTest < Test::Unit::TestCase

  def test_get_mat

    order = Order.first
    if order
      materials = Material
        .join(:products_materials, [:m_id])
        .join(:products, products__p_id: :products_materials__product_id)
        .join(:items, [:p_id])
        .join(:line_items, [:i_id], o_id: order.o_id)
        .select_group(:m_id, :m_name)
        .select_append{sum(:m_qty).as(m_qty)}
        .all

      bulks_in_use = []
      bulks_missing = []
      materials.each do |material|
        bulks = Bulk
          .where(b_loc: Location::W1)
          .where(m_id: material.m_id)
          .where(b_status: Bulk::IN_USE)
          .all

        bulks.each do |bulk|
          if bulk.b_qty >= material[:m_qty]
            bulks_in_use << bulk
          else
            bulks_missing << bulk
          end
        end
      end
    else
      p "No orders to test line_items"
    end
  end

end
