Sequel.migration do
  up do
    rename_table :credits, :credit_notes
    rename_column :credit_notes, :credit_id, :cr_id
    rename_column :credit_notes, :status, :cr_status
    rename_column :credit_notes, :description, :cr_desc
    rename_column :credit_notes, :ammount, :cr_ammount
    run 'ALTER TABLE credit_notes ADD `o_id` int(5) UNSIGNED'
    run 'ALTER TABLE credit_notes ADD `created_at` datetime DEFAULT NULL'
    run 'ALTER TABLE credit_notes ADD CONSTRAINT `credit_note_order_id` FOREIGN KEY (`o_id`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT;'


    run '
      CREATE TRIGGER cr_init BEFORE INSERT ON `credit_notes`
        FOR EACH ROW SET
        NEW.created_at = IFNULL(NEW.created_at, NOW());
    '
  end

  down do
  end
end

