Sequel.migration do
  change do
    run '
      CREATE TRIGGER br_init BEFORE INSERT ON `book_records`
      FOR EACH ROW SET
      NEW.created_at = IFNULL(NEW.created_at, NOW());
    '
  end
end