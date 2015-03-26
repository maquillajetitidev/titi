-- DROP TRIGGER IF EXISTS m_init;
-- show warnings;
DROP TABLE IF EXISTS `bulks`;

ALTER TABLE PM DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP TABLE IF EXISTS materials;
CREATE TABLE materials LIKE PM;
INSERT INTO materials (SELECT * FROM PM);
ALTER TABLE materials engine=innodb;
ALTER TABLE materials CHANGE pmID m_id int(5) UNSIGNED NOT NULL AUTO_INCREMENT;
ALTER TABLE materials ADD `c_id` tinyint(4) UNSIGNED NOT NULL DEFAULT 1 AFTER m_id;
ALTER TABLE materials CHANGE pmDesc m_name CHAR(50) DEFAULT NULL;
ALTER TABLE materials ADD `created_at` DATETIME;

-- ALTER TABLE materials CHANGE pmBulkQty m_qty DECIMAL(8,2) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE materials DROP pmBulkQty;

-- ALTER TABLE materials ADD m_price DECIMAL(6,3) UNSIGNED NOT NULL DEFAULT 0;
-- ALTER TABLE materials DROP m_price;

ALTER TABLE materials ADD PRIMARY KEY(m_id);
ALTER TABLE materials DROP index `pmID`;
CREATE UNIQUE INDEX m_name ON materials(m_name);
CREATE INDEX c_id ON materials(c_id);

CREATE TRIGGER m_init BEFORE INSERT ON `materials`
    FOR EACH ROW SET
    NEW.created_at = IFNULL(NEW.created_at, NOW());
show warnings;

UPDATE materials SET created_at=NOW();


-- -------------------------------------------------------------------------------------------


DROP TABLE IF EXISTS materials_categories;

CREATE TABLE materials_categories (
  c_id TINYINT(4) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  c_name VARCHAR(60) NOT NULL DEFAULT "INVALID",
  UNIQUE INDEX (c_name)
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci;



-- SHOW CREATE TABLE materials_categories;

INSERT INTO materials_categories (c_id, c_name) VALUES (1, "General");
INSERT INTO materials_categories (c_id, c_name) VALUES (2, "Envases");
UPDATE materials SET c_id=2 WHERE m_name LIKE "Envase%";
INSERT INTO materials_categories (c_id, c_name) VALUES (3, "Etiquetas preimpresas");
UPDATE materials SET c_id=3 WHERE m_name LIKE "Etiqueta%";
INSERT INTO materials_categories (c_id, c_name) VALUES (4, "Etiquetas imprimibles");
UPDATE materials SET c_id=4 WHERE m_name LIKE "Etiqueta ID%";
UPDATE materials SET c_id=4 WHERE m_name LIKE "Ribbon%";
INSERT INTO materials_categories (c_id, c_name) VALUES (5, "Gibre");
UPDATE materials SET c_id=5 WHERE m_name LIKE "Gibre%";
INSERT INTO materials_categories (c_id, c_name) VALUES (6, "Polvos");
UPDATE materials SET c_id=6 WHERE m_name LIKE "Polvo%";
INSERT INTO materials_categories (c_id, c_name) VALUES (7, "Maquillaje cremoso");
UPDATE materials SET c_id=7 WHERE m_name LIKE "Base cremosa%";
INSERT INTO materials_categories (c_id, c_name) VALUES (8, "Maquillaje al agua");
UPDATE materials SET c_id=8 WHERE m_name LIKE "Liquido corporal%";
UPDATE materials SET c_id=8 WHERE m_name LIKE "%mechitas%";

INSERT INTO materials_categories (c_id, c_name) VALUES (9, "Packaging");
UPDATE materials SET c_id=9 WHERE m_name = "Envase con volátil blanco para kit";
UPDATE materials SET c_id=9 WHERE m_name = "Envase: kit al agua";

INSERT INTO materials_categories (c_id, c_name) VALUES (10, "Insumos");
UPDATE materials SET c_id=10 WHERE m_name LIKE "Bolsas camiseta%";
UPDATE materials SET c_id=10 WHERE m_name LIKE "Papel%";
UPDATE materials SET c_id=10 WHERE m_name LIKE "Toner%";

INSERT INTO materials_categories (c_id, c_name) VALUES (11, "Bienes de uso");
UPDATE materials SET c_id=11 WHERE m_name LIKE "Impresora%";
UPDATE materials SET c_id=11 WHERE m_name LIKE "Scanner%";

ALTER TABLE materials ADD CONSTRAINT `mat_c_id` FOREIGN KEY (`c_id`) REFERENCES `materials_categories` (`c_id`) ON DELETE RESTRICT;
