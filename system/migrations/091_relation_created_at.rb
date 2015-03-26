Sequel.migration do
  up do
    run '
      ALTER TABLE products_to_distributors CHANGE created_at relation_created_at datetime DEFAULT NULL
    '

    run 'DROP TRIGGER ptd_insert'
    run '
      CREATE TRIGGER ptd_insert BEFORE INSERT ON `products_to_distributors`
        FOR EACH ROW BEGIN
          SET NEW.relation_created_at = IFNULL(NEW.relation_created_at, NOW());
        END
    '



    run '
      ALTER TABLE materials_to_distributors CHANGE created_at relation_created_at datetime DEFAULT NULL
    '
    run 'DROP TRIGGER mtd_insert'
    run '
      CREATE TRIGGER mtd_insert BEFORE INSERT ON `materials_to_distributors`
        FOR EACH ROW BEGIN
          SET NEW.relation_created_at = IFNULL(NEW.relation_created_at, NOW());
        END
    '

  end

  down do
  end
end



