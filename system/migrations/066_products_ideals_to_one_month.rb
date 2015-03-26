Sequel.migration do
  up do
    run "UPDATE products SET direct_ideal_stock = direct_ideal_stock /3, indirect_ideal_stock = indirect_ideal_stock /3, ideal_stock = ideal_stock /3"
  end

  down do
    run "UPDATE products SET direct_ideal_stock = direct_ideal_stock *3, indirect_ideal_stock = indirect_ideal_stock *3, ideal_stock = ideal_stock *3"
  end
end
