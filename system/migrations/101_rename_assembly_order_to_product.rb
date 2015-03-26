Sequel.migration do
  up do
    rename_table :assembly_order_to_product, :assembly_orders_to_products
  end

  down do
  end
end
