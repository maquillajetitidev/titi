Sequel.migration do
  up do
    run 'update products set real_markup = price / sale_cost where real_markup=0 and archived = 0 and price >0 and sale_cost > 0;'
    run 'update products set ideal_markup = real_markup where ideal_markup=0 and archived = 0;'
    run 'update products set real_markup = ideal_markup where real_markup=0 and archived = 0;'
  end

  down do
  end
end


