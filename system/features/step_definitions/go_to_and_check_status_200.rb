When(/^I go to returns$/) do
  visit "/sales/returns"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.return.title )
end

When(/^I go to labels$/) do
  visit "/admin/production/labels"
  page.status_code.should == 200
  expect(page).to have_content( t.labels.title )
end

When(/^I go to packaging_list$/) do
  visit "/admin/production/packaging/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.production.packaging_select.title )
end

When(/^I go to allocation_list$/) do
  visit "/admin/production/allocation/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.production.allocation_select.title )
end

When(/^I go to warehouse_arrivals$/) do
  visit "/admin/transport/arrivals/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.transport.arrivals.title )
end

When(/^I go to departure_pos_to_wh$/) do
  visit "/sales/transport/departures/pos_to_wh/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.transport.departures.pos_to_wh.title )
end

When(/^I go to departure_wh_to_pos$/) do
  visit "/admin/transport/departures/wh_to_pos/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.transport.departures.wh_to_pos.title )
end

When(/^I go to departure_wh_to_wh$/) do
  visit "/admin/transport/departures/wh_to_wh/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.transport.departures.wh_to_wh.title )
end

When(/^I go to store_arrivals$/) do
  visit "/sales/transport/arrivals/select"
  expect(page.status_code).to be( 200 )
  expect(page).to have_content( t.transport.arrivals.title )
end

When(/^I go to make_sale$/) do
  visit "/sales/make_sale"
  expect(page.status_code).to be( 200 )
  order = Order.last
  title = t.sales.make_sale.title(order.o_id, order.o_code_with_dash, 0, Utils::money_format(0, 2, "$ 0")).to_s
  expect(page).to have_content( title )
end
