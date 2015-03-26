Sequel.migration do
  up do
    run "ALTER TABLE products ADD public_sku CHAR(60) NOT NULL DEFAULT '' AFTER sku"
    run "UPDATE products SET public_sku=sku"
  end

  down do
    drop_column :products, :public_sku
  end
end


