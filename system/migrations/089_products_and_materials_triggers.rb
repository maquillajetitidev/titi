Sequel.migration do
  up do
    run 'DROP TRIGGER IF EXISTS p_init;'
    run 'DROP TRIGGER IF EXISTS m_set_last_price_update;'
    run 'DROP TRIGGER IF EXISTS p_set_name_and_last_price_update;'
    run 'DROP TRIGGER IF EXISTS p_init;'
    run 'DROP TRIGGER IF EXISTS p_update;'
    run 'DROP TRIGGER IF EXISTS m_init;'
    run 'DROP TRIGGER IF EXISTS m_update;'

    run '
      CREATE TRIGGER p_init BEFORE INSERT ON `products`
        FOR EACH ROW BEGIN
          SET NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ");
          SET NEW.created_at = NOW();
          SET NEW.price_updated_at = NOW();
        END
    '
    run '
      CREATE TRIGGER p_update BEFORE UPDATE ON `products`
        FOR EACH ROW BEGIN
          SET NEW.p_name = replace(replace(replace(concat(NEW.p_short_name," ",NEW.br_name," ",NEW.packaging," ",NEW.size," ",NEW.color," ",NEW.public_sku),"  "," "),"  "," "),"  "," ");
          IF OLD.buy_cost <> NEW.buy_cost THEN
            SET NEW.price_updated_at = NOW();
          END IF;
        END
    '
    run 'update products set price_updated_at = created_at where price_updated_at IS NULL;'

    run '
      CREATE TRIGGER m_init BEFORE INSERT ON `materials`
        FOR EACH ROW BEGIN
          SET NEW.created_at = NOW();
          SET NEW.price_updated_at = NOW();
        END
    '
    run '
      CREATE TRIGGER m_update BEFORE UPDATE ON `materials`
        FOR EACH ROW BEGIN
          IF OLD.m_price <> NEW.m_price THEN
            SET NEW.price_updated_at = NOW();
          END IF;
        END
    '
    run 'update materials set price_updated_at = created_at where price_updated_at IS NULL;'

  end

  down do
    run 'DROP TRIGGER IF EXISTS p_init;'
    run 'DROP TRIGGER IF EXISTS m_set_last_price_update;'
    run 'DROP TRIGGER IF EXISTS p_set_name_and_last_price_update;'
    run 'DROP TRIGGER IF EXISTS p_init;'
    run 'DROP TRIGGER IF EXISTS p_update;'
    run 'DROP TRIGGER IF EXISTS m_init;'
    run 'DROP TRIGGER IF EXISTS m_update;'
  end
end
