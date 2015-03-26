Sequel.migration do
  up do
    run "ALTER TABLE products ADD `tercerized` tinyint(1) UNSIGNED NOT NULL DEFAULT 0 after `stock_warehouse_2`"
  end

  down do
    drop_column :products, :tercerized
  end
end
