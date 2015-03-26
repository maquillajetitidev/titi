Sequel.migration do
  up do
    run '
      CREATE TABLE `sales_to_returns` (
       `sale` int(5) UNSIGNED NOT NULL,
       `return` int(5) UNSIGNED NOT NULL,
       `created_at` datetime DEFAULT NULL,
       PRIMARY KEY (`sale`, `return`),
       CONSTRAINT `str_sale` FOREIGN KEY (`sale`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT,
       CONSTRAINT `str_return` FOREIGN KEY (`return`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT
       ) ENGINE=InnoDB  ROW_FORMAT=DYNAMIC;
    '

    run '
      CREATE TRIGGER str_init BEFORE INSERT ON `sales_to_returns`
        FOR EACH ROW SET
        NEW.created_at = IFNULL(NEW.created_at, NOW());
    '
  end

  down do
    run 'DROP TABLE sales_to_returns'
  end
end
