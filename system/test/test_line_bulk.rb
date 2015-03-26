 require_relative 'prerequisites'

class LineBulkTest < Test::Unit::TestCase

  def test_only_inter_warehouse_orders_can_have_bulks
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      order = Order.new.create_or_load(Order::PACKAGING)
      order.add_bulk Bulk.new.get_rand
      assert order.errors.size == 1
      assert_equal R18n::t.errors.not_a_inter_warehouse_order, order.errors.first[1][0]
    end
  end

  def test_should_add_bulk_to_order
    DB.transaction(rollback: :always, isolation: :uncommitted) do
      order = Order.new.create_or_load Order::WH_TO_WH
      bulk = Bulk.new.create 5, 1, Location::SYS
      bulk = Bulk.new.get_for_transport bulk.b_id, order.o_id
      assert bulk.errors.empty?, "The bulk has errors: #{bulk.errors.to_a.flatten.join(": ")}"
      assert order.errors.empty?, "The order has errors: #{order.errors.to_a.flatten.join(": ")}"
      pre = order.bulks.count
      order.add_bulk bulk
      assert_equal pre+1, order.bulks.count
    end
  end

end
