Sequel.migration do
  up do
    set_column_default :products, :p_name, "NEW Varias"
    set_column_default :products, :packaging, ""
    set_column_default :products, :br_name, "Varias"
    set_column_default :products, :br_id, 6
    set_column_default :products, :sku, ""
    run 'ALTER TABLE products CHANGE description description text NULL'
    run 'ALTER TABLE products CHANGE notes notes text NULL'
  end

  down do
  end
end
