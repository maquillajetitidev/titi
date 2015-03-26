Sequel.migration do
  up do
    run 'DROP TRIGGER  p_set_name_and_last_price_update;'
    run '
      CREATE TRIGGER p_set_name_and_last_price_update BEFORE UPDATE ON `products`
        FOR EACH ROW BEGIN
          SET NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ");
          IF OLD.buy_cost <> NEW.buy_cost THEN
            SET NEW.price_updated_at = NOW();
          END IF;
        END
    '

    run 'DROP TRIGGER IF EXISTS `p_init`;'
    run '
      CREATE TRIGGER p_init BEFORE INSERT ON `products`
        FOR EACH ROW BEGIN
          SET NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ");
          SET NEW.created_at = NOW();
        END
    '
    run 'update products set public_sku=rand() where p_name like "NEW %" AND public_sku = "";'
  end

  down do
    run 'DROP TRIGGER p_set_name_and_last_price_update;'
    run 'DROP TRIGGER p_init;'
  end
end
