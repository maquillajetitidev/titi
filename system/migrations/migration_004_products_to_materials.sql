DROP TABLE IF EXISTS products_materials;
CREATE TABLE products_materials LIKE catalogo_articulos_PM;
INSERT INTO products_materials (SELECT * FROM catalogo_articulos_PM);

ALTER TABLE products_materials CHANGE artID product_id int(5) UNSIGNED NOT NULL;
ALTER TABLE products_materials CHANGE pmID m_id int(5) UNSIGNED NOT NULL;
ALTER TABLE products_materials CHANGE pmQty m_qty decimal(8,2) UNSIGNED NOT NULL;

CREATE UNIQUE INDEX prod_mat ON products_materials(product_id, m_id);
CREATE UNIQUE INDEX mat_prod ON products_materials(m_id, product_id);
ALTER TABLE products_materials DROP index `artID`;


ALTER TABLE PM CHANGE `pmBulkQty` `pmBulkQty` DECIMAL(8,2) unsigned NOT NULL DEFAULT '0';

