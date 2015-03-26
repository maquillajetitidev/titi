Sequel.migration do
  up do
    run "ALTER TABLE products ADD `stock_store_2` int(4) UNSIGNED NOT NULL DEFAULT 0 after `stock_store_1`"
    run 'ALTER TABLE products change `ideal_stock` `ideal_stock` int(4) UNSIGNED NOT NULL DEFAULT 0 after `sku`;'
  end

  down do
    drop_column :products, :stock_store_2
  end
end
