Sequel.migration do
  up do
    run "ALTER TABLE products add `direct_ideal_stock` decimal(6,2) unsigned default 0 NOT NULL AFTER public_sku"
    run "ALTER TABLE products add `indirect_ideal_stock` decimal(6,2) unsigned default 0 NOT NULL AFTER direct_ideal_stock"
    run "UPDATE products SET direct_ideal_stock = ideal_stock"
    run 'DROP TRIGGER p_name_init'
    run '
      CREATE TRIGGER p_name_init_and_ideal_stock BEFORE UPDATE ON `products`
      FOR EACH ROW SET
      NEW.ideal_stock = NEW.direct_ideal_stock + NEW.indirect_ideal_stock,
      NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ")
    '
  end

  down do
    drop_column :products, :direct_ideal_stock 
    drop_column :products, :indirect_ideal_stock 
    run 'DROP TRIGGER p_name_init'
    run 'DROP TRIGGER p_name_init_and_ideal_stock'
  end
end


    