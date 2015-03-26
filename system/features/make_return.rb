def get_a_sale_order
  rnd = rand( Order.filter(type: Order::SALE, o_status: Order::FINISHED).count(:o_id) )
  Order.where(type: Order::SALE, o_status: Order::FINISHED).limit(10, rnd).all.sample(1)[0]
end


When(/^It ask for a order code$/) do
  expect(page).to have_content( t.return.verify_order_code_legend )
end

When(/^I give it a valid code$/) do
  @order = get_a_sale_order
  fill_in( "o_code", with: @order.o_code)
  click_button( t.actions.verify )
  expect(page.status_code).to be(200)
  expect(page).to have_content( t.return.sale_details @order.o_id, @order.o_code_with_dash )
end

When(/^I give it an invalid code, then I should see an error$/) do
  fill_in( "o_code", with: '¯\(°_o)/¯. I DUNNO LOL.')
  click_button( t.actions.verify )
  expect(page.status_code).to be(200)
  page.should have_content( "#{t.errors.inexistent_order.to_s}: #{t.errors.invalid_order_id.to_s}" )
end

When(/^I give it a valid code, but ist's not a sale, then I should see an error$/) do
  o_code = Order.select(:o_code).filter(type: Order::CREDIT_NOTE).first
  fill_in( "o_code", with: "#{o_code}")
  click_button( t.actions.verify )
  expect(page.status_code).to be(200)
  expect(page).to have_content( "#{t.errors.inexistent_order.to_s}: #{t.errors.invalid_order_id.to_s}" )
end

When(/^The order is a sale$/) do
  @order.type.should == Order::SALE
end

When(/^The order is finished$/) do
  @order.o_status.should == Order::FINISHED
end

When(/^The order has items$/) do
  count = page.all('.item').count
  puts "#{count} items in order #{@order.o_id} (#{@order.o_code_with_dash})"
  count.should > 0
end

Then(/^It should ask for the items to be returned$/) do
  page.should have_content( t.return.title )
  page.should have_content( t.return.scan_label )
  page.should have_content( t.return.sale_details @order.o_id, @order.o_code_with_dash )
  items = page.all('.item')
  if items.empty?
    puts "There are no items  !"
    "There are no items !".should == false
  end
  @i_id = @order.items.first.i_id
  fill_in( "i_id", with: @i_id)
  click_button( t.actions.confirm )
  page.all('.item').first.first('td').text.should == @i_id
end

And(/^I should be able to finish the order and download the pdf$/) do
  click_button( t.actions.finish )
  # pending # express the regexp above with the code you wish you had
#   order = Order.new.get_orders_at_location_with_type_and_status(Location::S1, Order::CREDIT_NOTE, Order::OPEN).last
#   page.should have_content( t.credit_note.generated(Utils::money_format(order.credit_total, 2), order.o_code_with_dash) )
#   click_button( t.actions.print )
end

And(/^I give it an used code, then I should see an error$/) do
  fill_in( "o_code", with: @order.o_code)
  click_button( t.actions.verify )
  page.status_code.should == 200
  page.should have_content( t.return.sale_details @order.o_id, @order.o_code_with_dash )

  fill_in( "i_id", with: @i_id)
  click_button( t.actions.confirm )
  page.should have_content( "#{t.return.errors.invalid_status.to_s}: #{t.return.errors.this_item_is_not_in_sold_status.to_s}" )
  click_button( t.actions.cancel )
end

