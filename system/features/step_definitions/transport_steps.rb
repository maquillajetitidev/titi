When /^I fill with some items from s1$/ do
  init_r18

  count = page.all('.item').count
  i_id = add_and_remove_item Location::S1
  page.all('.item').count.should == count
  count = page.all('.item').count
  p "Adding new item #{count + 1}"
  add i_id

  page.all('.item').count.should == count + 1
  count = page.all('.item').count
  p "Removing item #{count - 1}"
  remove_item i_id
  page.all('.item').count.should == count -1

  count = page.all('.item').count
  add_invalid
  page.all('.item').count.should == count

  count = page.all('.item').count
  i_id = add_ready_item Location::S1
  page.all('.item').count.should == count + 1

  p "Adding same item again #{page.all('.item').count}"
  count = page.all('.item').count
  add i_id
  page.all('.item').count.should == count

  count = page.all('.item').count
  p "Adding new item #{count + 1}"
  i_id = add_ready_item Location::S1
  page.all('.item').count.should == count + 1

  puts "Order: #{get_o_id_from_current_path}"
end



When /^I fill with some items from w1$/ do
  init_r18

  count = page.all('.item').count
  p "Initial count: #{count}"
  i_id = add_and_remove_item Location::W1
  page.all('.item').count.should == count
  add i_id

  page.all('.item').count.should == count + 1
  count = page.all('.item').count
  remove_item i_id
  page.all('.item').count.should == count -1

  count = page.all('.item').count
  add_invalid
  page.all('.item').count.should == count

  count = page.all('.item').count
  i_id = add_ready_item Location::W1
  page.all('.item').count.should == count + 1

  p "Adding same item again #{page.all('.item').count}"
  count = page.all('.item').count
  add i_id
  page.all('.item').count.should == count

  count = page.all('.item').count
  p "Adding new item #{count + 1}"
  i_id = add_ready_item Location::W1
  page.all('.item').count.should == count + 1
  count = page.all('.item').count
  p "Final count: #{count}"
end


When /^I fill with some items from w2$/ do
  init_r18

  count = page.all('.item').count
  p "Initial count: #{count}"
  i_id = add_and_remove_item Location::W2
  page.all('.item').count.should == count
  add i_id

  page.all('.item').count.should == count + 1
  count = page.all('.item').count
  remove_item i_id
  page.all('.item').count.should == count -1

  count = page.all('.item').count
  add_invalid
  page.all('.item').count.should == count

  count = page.all('.item').count
  i_id = add_ready_item Location::W2
  page.all('.item').count.should == count + 1

  p "Adding same item again #{page.all('.item').count}"
  count = page.all('.item').count
  add i_id
  page.all('.item').count.should == count

  count = page.all('.item').count
  p "Adding new item #{count + 1}"
  i_id = add_ready_item Location::W2
  page.all('.item').count.should == count + 1
  count = page.all('.item').count
  p "Final count: #{count}"
end


When /^I fill with some bulks from w2$/ do
  init_r18

  count = page.all('.item').count
  b_id = add_and_remove_bulk Location::W2
  page.all('.item').count.should == count

  add b_id
  page.all('.item').count.should == count + 1

  count = page.all('.item').count
  remove_bulk b_id
  page.all('.item').count.should == count -1

  count = page.all('.item').count
  add_invalid
  page.all('.item').count.should == count

  count = page.all('.item').count
  b_id = add_ready_bulk Location::W2
  page.all('.item').count.should == count + 1

  p "Adding same bulk again #{page.all('.item').count}"
  count = page.all('.item').count
  add b_id
  page.all('.item').count.should == count

  count = page.all('.item').count
  p "Adding new bulk #{count + 1}"
  b_id = add_ready_bulk Location::W2
  page.all('.item').count.should == count + 1
end




def init_r18
  @r18 = R18n::I18n.new('es', './locales')
end

def add_and_remove_item location
  @count = page.all('.item').count
  item = Item.filter(i_status: Item::READY, i_loc: location).first
  add item.i_id
  click_button( @r18.t.actions.undo )
  page.all('.item').count.should == @count
  item.i_id
end

def add_and_remove_bulk location
  @count = page.all('.item').count
  bulk = Bulk.filter(b_status: [Bulk::NEW, Bulk::IN_USE], b_loc: location).first
  add bulk.b_id
  click_button( @r18.t.actions.undo )
  page.all('.item').count.should == @count
  bulk.b_id
end

def remove_item id
  count = page.all('.item').count
  p "Removing one item of #{count}"
  click_link( "Remover un item de la orden" )
  add2 id
  page.all('.item').count.should == count - 1
end

def remove_bulk id
  count = page.all('.item').count
  p "Removing one bulk of #{count}"
  click_link( "Remover un granel de la orden" )
  add2 id
  page.all('.item').count.should == count - 1
end

def add_ready_item location
  count = page.all('.item').count
  item = Item.filter(i_status: Item::READY, i_loc: location).first
  add item.i_id
  page.all('.item').count.should == count + 1
  item.i_id
end

def add_ready_bulk location
  count = page.all('.item').count
  bulk = Bulk.filter(b_status: [Bulk::NEW, Bulk::IN_USE], b_loc: location).first
  add bulk.b_id
  page.all('.item').count.should == count + 1
  bulk.b_id
end


def add id
  fill_in 'i_id', with: id
  click_button( @r18.t.actions.ok )
  id
end

def add2 id
  fill_in 'id', with: id
  click_button( @r18.t.actions.ok )
  id
end

def add_invalid
  @count = page.all('.item').count
  add "hola"
  with_scope('.flash') { page.should have_content( @r18.t.errors.invalid_label ) }
  page.all('.item').count.should == @count
end

