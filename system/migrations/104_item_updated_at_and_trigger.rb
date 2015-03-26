Sequel.migration do
  up do
    run 'ALTER TABLE items ADD updated_at datetime DEFAULT NULL AFTER created_at;'
    run 'UPDATE items SET updated_at = NOW();;'

    run '
      CREATE TRIGGER i_update BEFORE UPDATE ON `items`
        FOR EACH ROW BEGIN
          SET NEW.updated_at = NOW();
        END
    '
  end

  down do
    run 'DROP TRIGGER i_update;'
    run 'ALTER TABLE items DROP updated_at;'
  end
end
