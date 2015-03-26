

DROP TABLE IF EXISTS products_parts;
ALTER TABLE catalogo_articulos_comp DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE products_parts LIKE catalogo_articulos_comp;

INSERT INTO products_parts (SELECT * FROM catalogo_articulos_comp);

ALTER TABLE products_parts CHANGE artID product_id int(5) UNSIGNED NOT NULL;
ALTER TABLE products_parts CHANGE compID part_id int(5) UNSIGNED NOT NULL;
ALTER TABLE products_parts CHANGE compQty part_qty decimal(8,2) UNSIGNED NOT NULL;

ALTER TABLE products_parts ADD PRIMARY KEY(product_id, part_id);
CREATE UNIQUE INDEX part_prod ON products_parts(part_id, product_id);
ALTER TABLE products_parts DROP index `artID`;


ALTER TABLE  products_parts ADD CONSTRAINT `part_product_id` FOREIGN KEY (`part_id`) REFERENCES `products` (`p_id`) ON DELETE RESTRICT;

