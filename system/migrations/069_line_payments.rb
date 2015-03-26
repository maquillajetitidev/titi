Sequel.migration do
  up do
    run '
      CREATE TABLE `line_payments` (
       `lp_id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT,
       `o_id` int(5) UNSIGNED NOT NULL DEFAULT 0,
       `payment_type` char(12) NOT NULL DEFAULT "INVALID",
       `payment_code` char(7) NOT NULL DEFAULT "INVALID",
       `payment_ammount` decimal(8, 2) NOT NULL DEFAULT 0,
       `created_at` datetime DEFAULT NULL,
       PRIMARY KEY (`lp_id`),
       KEY `lp_o_id` (`o_id`),
       CONSTRAINT `lp_order_id` FOREIGN KEY (`o_id`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT
       ) ENGINE=InnoDB  ROW_FORMAT=DYNAMIC;
    '

    run '
      CREATE TRIGGER lp_init BEFORE INSERT ON `line_payments`
        FOR EACH ROW SET
        NEW.created_at = IFNULL(NEW.created_at, NOW());
    '
  end

  down do
    run 'DROP TABLE line_payments'
  end
end
