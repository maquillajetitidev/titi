require_relative 'prerequisites'

class SalesReportTest < Test::Unit::TestCase

  # def test_base
  #   sales_report = []
  #   Product.new.get_live.order(:p_name).limit(5).all.each do |product|
  #     ap "#{product.p_name} (#{product.p_id})"

  #     sales = DB.fetch("
  #         select DATE_FORMAT(orders.created_at,'%y%m') as date, count(1) as qty
  #         from orders
  #         join line_items using (o_id)
  #         join items using (i_id)
  #         where type = 'SALE' and p_id = #{product.p_id}
  #         group by p_id, year(orders.created_at) ,month(orders.created_at), orders.created_at, items.p_name
  #         order by p_name, year(orders.created_at) ,month(orders.created_at)
  #       ").all
  #     product[:sales] = sales
  #     sales_report << product
  #   end
  #   # ap sales_report
  # end

end
