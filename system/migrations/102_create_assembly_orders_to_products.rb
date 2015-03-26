Sequel.migration do
  up do
    run 'DROP TABLE IF EXISTS assembly_orders_to_products'
    run '

      CREATE TABLE `assembly_orders_to_products` (
       `aotp_id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT,
       `o_id` int(5) UNSIGNED NOT NULL,
       `p_id` int(5) UNSIGNED NOT NULL,
       `created_at` datetime DEFAULT NULL,
       PRIMARY KEY (`aotp_id`),
       UNIQUE KEY `aotp_oid` (o_id),
       KEY `aotp_pid` (`p_id`),
       CONSTRAINT `aotp_order_id` FOREIGN KEY (`o_id`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT,
       CONSTRAINT `aotp_prod_id` FOREIGN KEY (`p_id`) REFERENCES `products` (`p_id`) ON DELETE RESTRICT
       ) ENGINE=InnoDB  ROW_FORMAT=DYNAMIC;
    '

    run '
      CREATE TRIGGER assembly_order_to_product_init BEFORE INSERT ON `assembly_orders_to_products`
        FOR EACH ROW SET
        NEW.created_at = IFNULL(NEW.created_at, NOW());
    '

  end

  down do
  end
end
