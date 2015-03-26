Sequel.migration do
  change do
    run "ALTER TABLE products CHANGE sku sku CHAR(60)"
    run "UPDATE products SET sku = NULL WHERE sku = ''"
    run "ALTER TABLE products ADD UNIQUE KEY `p_sku` (sku);"
  end
end


