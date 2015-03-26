DROP TABLE IF EXISTS `bulks`;

ALTER TABLE PM DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE TABLE bulks LIKE PM;

ALTER TABLE bulks ADD `b_id` char(17) COLLATE utf8mb4_unicode_ci DEFAULT NULL FIRST;
ALTER TABLE bulks CHANGE pmID m_id int(5) unsigned DEFAULT NULL;
ALTER TABLE bulks CHANGE `pmBulkQty` `b_qty` decimal(8,2) unsigned NOT NULL DEFAULT '0';
ALTER TABLE bulks DROP pmDesc;

ALTER TABLE bulks ADD `b_price` decimal(12,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE bulks ADD `b_status` char(12) NOT NULL DEFAULT 'UNDEFINED';
ALTER TABLE bulks ADD `b_printed` tinyint(1) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE bulks ADD `b_loc` char(12) NOT NULL DEFAULT 'UNDEFINED';
ALTER TABLE bulks ADD `created_at` DATETIME;
ALTER TABLE bulks DROP  KEY `pmID`;

UPDATE bulks SET `b_status` = "IN_USE", created_at=NOW(), b_id=CONCAT_WS(".", DATE_FORMAT(NOW(),"%y.%m.%d"), left( uuid(), 8));

ALTER TABLE bulks ADD PRIMARY KEY `bulk_id` (`b_id`);
ALTER TABLE bulks ADD KEY `m_id__b_price` (m_id, b_price);
ALTER TABLE bulks ADD KEY `bulk_status` (`b_status`);
ALTER TABLE bulks ADD KEY `bulk_location` (`b_loc`);
ALTER TABLE bulks ADD KEY `bulk_created` (`created_at`);

ALTER TABLE bulks ADD CONSTRAINT `bulks_m_id` FOREIGN KEY (`m_id`) REFERENCES `materials` (`m_id`) ON DELETE RESTRICT;


DELIMITER $$
CREATE TRIGGER b_init BEFORE INSERT ON `bulks` 
  FOR EACH ROW BEGIN
  SET @last_b_id := CONCAT_WS("", right(DATE_FORMAT(NOW(),"%y"),1), DATE_FORMAT(NOW(),"%u"), "-B" , left( uuid(), 8));
  SET NEW.created_at = IFNULL(NEW.created_at, NOW()), NEW.b_id = @last_b_id;
END $$
DELIMITER ;



INSERT INTO bulks (m_id,b_qty,b_price,b_loc,b_status) SELECT pmID, pmBulkQty, 0, "WAREHOUSE_1", "IN_USE" FROM PM WHERE pmBulkQty > 0;

