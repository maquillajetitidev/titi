DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
 `i_id` char(17) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
 `p_id` int(5) unsigned DEFAULT NULL,
 `p_name` VARCHAR(60) NOT NULL DEFAULT "INVALID",
 `i_price` decimal(6,2) unsigned NOT NULL DEFAULT '0.00',
 `i_price_pro` decimal(6,2) unsigned NOT NULL DEFAULT '0.00',
 `i_status` char(12) NOT NULL DEFAULT 'NEW',
 `i_loc` char(12) NOT NULL DEFAULT 'UNDEFINED',
 `created_at` datetime DEFAULT NULL,
 PRIMARY KEY (`i_id`),
 KEY `item_p_id` (`p_id`),
 KEY `item_status` (`i_status`),
 KEY `item_location` (`i_loc`),
 KEY `item_created` (`created_at`),
 CONSTRAINT `items_p_id` FOREIGN KEY (`p_id`) REFERENCES `products` (`p_id`) ON DELETE RESTRICT
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DELIMITER $$
CREATE TRIGGER i_init BEFORE INSERT ON `items` 
  FOR EACH ROW BEGIN
  SET @last_i_id := CONCAT_WS("", right(DATE_FORMAT(NOW(),"%y"),1), DATE_FORMAT(NOW(),"%u"), "-" , left( uuid(), 8));
  SET NEW.created_at = IFNULL(NEW.created_at, NOW()), NEW.i_id = @last_i_id;
END $$
DELIMITER ;

-- INSERT INTO items () VALUES ();
-- SELECT @last_i_id;