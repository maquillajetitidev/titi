Sequel.migration do
  up do
    run 'ALTER TABLE products ADD created_at datetime DEFAULT NULL AFTER img_extra;'
    run 'ALTER TABLE products ADD price_updated_at datetime DEFAULT NULL AFTER created_at;'

    run 'DROP TRIGGER  p_name_init;'
    run '
      CREATE TRIGGER p_set_name_and_last_price_update BEFORE UPDATE ON `products`
        FOR EACH ROW BEGIN
          SET NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ");
          IF (OLD.buy_cost <> NEW.buy_cost OR OLD.ideal_markup <> NEW.ideal_markup OR OLD.real_markup <> NEW.real_markup OR OLD.exact_price <> NEW.exact_price) THEN
            SET NEW.price_updated_at = NOW();
          ELSE
            SET NEW.price_updated_at = OLD.price_updated_at;
          END IF;
        END
    '
  end

  down do
    run 'ALTER TABLE products DROP created_at;'
    run 'ALTER TABLE products DROP price_updated_at;'
    run 'DROP TRIGGER p_set_name_and_last_price_update;'
    run '
      CREATE TRIGGER p_name_init BEFORE UPDATE ON `products`
      FOR EACH ROW SET
      NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ")
    '
  end
end
