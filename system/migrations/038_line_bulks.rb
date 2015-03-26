Sequel.migration do
  up do
    run '

      CREATE TABLE `line_bulks` (
       `li_id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT,
       `o_id` int(5) UNSIGNED NOT NULL,
       `b_id` char(13) NOT NULL,
       `created_at` datetime DEFAULT NULL,
       PRIMARY KEY (`li_id`),
       UNIQUE KEY `o_i` (o_id, b_id),
       KEY `loid` (`o_id`),
       KEY `libd` (`b_id`),
       CONSTRAINT `lb_order_id` FOREIGN KEY (`o_id`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT,
       CONSTRAINT `lb_bulk_id` FOREIGN KEY (`b_id`) REFERENCES `bulks` (`b_id`) ON DELETE RESTRICT
       ) ENGINE=InnoDB  ROW_FORMAT=DYNAMIC;
    '

    run '
      CREATE TRIGGER lb_init BEFORE INSERT ON `line_bulks`
        FOR EACH ROW SET
        NEW.created_at = IFNULL(NEW.created_at, NOW());
    '

  end

  down do
  end
end
