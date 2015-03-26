Sequel.migration do
  up do
    rename_column :products, :brand_id , :br_id

    create_table! (:brands) do
      primary_key :br_id
      column :br_name, String, fixed: true, size: 20, null: false, index: true
    end

    run 'INSERT INTO brands (br_name) SELECT DISTINCT brand FROM products;'
    run 'UPDATE products SET br_id = (SELECT br_id FROM brands WHERE br_name=brand);'

    run 'ALTER TABLE products ADD CONSTRAINT `brand_id` FOREIGN KEY (`br_id`) REFERENCES `brands` (`br_id`) ON DELETE RESTRICT;'

  end

  down do
    drop_table(:brands)
    rename_column :products, :br_id , :brand_id
  end
end
