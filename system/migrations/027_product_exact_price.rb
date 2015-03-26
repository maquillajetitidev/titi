Sequel.migration do
  up do
    run "ALTER TABLE products ADD `exact_price` decimal(9,5) UNSIGNED NOT NULL DEFAULT 0 after `real_markup`"
    run "UPDATE products set exact_price = price"
  end

  down do
    drop_column :products, :exact_price
  end
end
