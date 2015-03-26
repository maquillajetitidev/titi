Sequel.migration do
  up do
    run 'update products set price =1  where price=0 and archived = 1;'
    run 'update products set exact_price =1  where exact_price=0 and archived = 1;'
    run 'update products set buy_cost = 0.1  where buy_cost+sale_cost=0 and archived = 1;'
    run 'update products set sale_cost = 0.1  where sale_cost=0 and archived = 1;'
    run 'update products set sale_cost = buy_cost  where sale_cost=0 and buy_cost > 0 and archived = 1;'
    run 'update products set real_markup = price / sale_cost where real_markup=0 and archived = 1 and price >0 and sale_cost > 0;'
    run 'update products set ideal_markup = real_markup where ideal_markup=0 and archived = 1;'
    run 'update products set real_markup = ideal_markup where real_markup=0 and archived = 1;'
  end

  down do
  end
end
