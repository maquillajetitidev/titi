DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
 `o_id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT,
 `type` char(10) NOT NULL DEFAULT 'UNDEFINED',
 `o_status` char(12) NOT NULL DEFAULT 'UNDEFINED',
 `o_loc` char(12) NOT NULL DEFAULT 'UNDEFINED',
 `u_id` int(5) unsigned NOT NULL DEFAULT 1,
 `created_at` datetime DEFAULT NULL,
 PRIMARY KEY (`o_id`),
 KEY `order_type` (`type`),
 KEY `order_status` (`o_status`),
 KEY `order_location` (`o_loc`),
 KEY `order_created` (`created_at`)
 ) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TRIGGER o_init BEFORE INSERT ON `orders`
  FOR EACH ROW SET
  NEW.created_at = IFNULL(NEW.created_at, NOW());



DROP TABLE IF EXISTS `line_items`;
CREATE TABLE `line_items` (
 `li_id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT,
 `o_id` int(5) UNSIGNED NOT NULL,
 `i_id` char(17) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
 `created_at` datetime DEFAULT NULL,
 PRIMARY KEY (`li_id`),
 UNIQUE KEY `o_i` (o_id, i_id),
 KEY `loid` (`o_id`),
 KEY `liid` (`i_id`),
 CONSTRAINT `l_order_id` FOREIGN KEY (`o_id`) REFERENCES `orders` (`o_id`) ON DELETE RESTRICT,
 CONSTRAINT `l_item_id` FOREIGN KEY (`i_id`) REFERENCES `items` (`i_id`) ON DELETE RESTRICT
 ) ENGINE=InnoDB  ROW_FORMAT=DYNAMIC;

CREATE TRIGGER li_init BEFORE INSERT ON `line_items`
  FOR EACH ROW SET
  NEW.created_at = IFNULL(NEW.created_at, NOW());

