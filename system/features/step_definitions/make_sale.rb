
Then(/^I should be able to cancel$/) do
  click_button t.actions.cancel
  expect(page.status_code).to be( 200 )
end

Then(/^I should not be able to checkout$/) do
  click_button t.sales.make_sale.checkout
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.sales.make_sale.cant_checkout_empty_order )
end

When(/^I add an item to current sale$/) do
  item = Item.where(i_loc: Location::S1, i_status: Item::READY).first
  fill_in( "i_id", with: item.i_id)
  find(:id, 'i_id').native.send_keys("\n")
  title = t.actions.changed_item_status(ConstantsTranslator.new(Item::ON_CART).t)
  expect(page).to have_content( title )
end


Then(/^I should be able to remove the item$/) do
  visit "/sales/make_sale/remove_item"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.sales.make_sale.remove_item )
  item = Item.where(i_loc: Location::S1, i_status: Item::ON_CART).first
  fill_in( "id", with: item.i_id)
  find(:id, 'id').native.send_keys("\n")
  expect(page).to have_content( t.item.deleted_from_order )
end

Then(/^I should be able to checkout$/) do
  click_button t.sales.make_sale.checkout
  order = Order.last
  expect(page).to have_content( t.sales.checkout.title order.o_code_with_dash )
  click_button "finish"
end
