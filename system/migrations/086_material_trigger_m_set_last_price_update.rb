Sequel.migration do
  up do
    run 'ALTER TABLE materials ADD price_updated_at datetime DEFAULT NULL AFTER created_at;'
    run '
      CREATE TRIGGER m_set_last_price_update BEFORE UPDATE ON `materials`
        FOR EACH ROW BEGIN
          IF OLD.m_price <> NEW.m_price THEN
            SET NEW.price_updated_at = NOW();
          END IF;
        END
    '
  end

  down do
    run 'ALTER TABLE products DROP price_updated_at;'
    run 'DROP TRIGGER m_set_last_price_update;'
  end
end
