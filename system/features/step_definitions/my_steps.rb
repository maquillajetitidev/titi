def get_o_id_from_current_path
  o_id = current_path.scan(/\d+/).last.to_i
  raise "Trying to find a numeric ID in #{current_path} but found none" if o_id.to_i == 0
  o_id
end

When(/^I type "(.*?)" in admin_username$/) do |arg1|
  fill_in 'admin_username', with: 'aburone'
end

When(/^I type "(.*?)" in password$/) do |arg1|
  fill_in 'admin_password', with: '1234'
end

When(/^I click "(.*?)"$/) do |arg1|
  click_button arg1
end



When /^I select the last item and click on the last link$/ do
  items = page.all('.item')

  if items.empty?
    puts "There are no items to click!"
    "There are no items to click!".should == false
  else
    node =  items.last.first(:link)
    puts "Loading #{node.text} > #{node[:href]}"
    node.click
  end
end


When /^I verify all items$/ do
  i_ids = []
  page.all('.item').each { |item| i_ids <<  item.first('td').text }
  i_ids.each do |i_id|

    fill_in 'i_id', with: "#{i_id}"
    click_button("Aceptar")
    with_scope('.flash') { page.should have_content("Etiqueta #{i_id} verificada con ") }
  end
end



Then /^Show me the page$/ do
  puts body
end

Then /^show me the session cookies$/ do
  ap Capybara.current_session.driver.request.cookies
end

Then /^within id (.+) I should see (\d+) (.+)$/ do |id, number, classs|
  with_scope(id) do
    page.should have_css("\##{classs}", count: number.to_i)
  end
end

Then /^I should see (\d+) (.+)$/ do |number, classs|
  page.should have_css(".#{classs}", count: number.to_i)
end



When /^I click on "([^\"]+)"$/ do |text|
  matcher = ['*', { :text => text }]
  element = page.find(:css, *matcher)
  while better_match = element.first(:css, *matcher)
    element = better_match
  end
  element.click
end

# Use this to fill in an entire form with data from a table. Example:
#   When I fill in the following:
#     | Account Number | 5002       |
#     | Expiry date    | 2009-11-01 |
#     | Note           | Nice guy   |
#     | Wants Email?   |            |
# TODO: Add support for checkbox, select or option based on naming conventions.
When /^(?:|I )fill in the following(?: within "([^\"]*)")?:$/ do |selector, fields|
  with_scope(selector) do
    fields.rows_hash.each do |name, value|
      step %{I fill in "#{name}" with "#{value}"}
    end
  end
end



When /^selectors test$/ do
  included_defs.each do |data_set_name|
    click_button "+"
    select_node = all(:css, '.input-many-item select').last # There may be more than one of these
    select_node.find(:xpath, XPath::HTML.option(data_set_name), :message => "cannot select option with text '#{data_set_name}'").select_option
  end
  # all is like find, but it returns an array of matching nodes, so I can use .last and always get the last one.
  page.should have_css("#table", :text => "[Name]")
  page.should have_css('h2', :text => 'stuff')
end


def click_link_or_button(locator)
  find(:link_or_button, locator).click
end
# alias_method :click_on, :click_link_or_button
