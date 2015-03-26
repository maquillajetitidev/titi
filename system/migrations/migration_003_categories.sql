
DROP TABLE IF EXISTS categories;
ALTER TABLE catalogo_categorias DEFAULT CHARSET=utf8mb4 COLLATE utf8mb4_unicode_ci ;

CREATE TABLE categories LIKE catalogo_categorias;
INSERT INTO categories (SELECT * FROM catalogo_categorias);

ALTER TABLE categories CHANGE id c_id int(5) UNSIGNED NOT NULL AUTO_INCREMENT;
ALTER TABLE categories CHANGE Nombre c_name VARCHAR(60)  CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "INVALID";
ALTER TABLE categories CHANGE VerPublico is_published tinyint(1) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE categories CHANGE Descripcion description TEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL ;
ALTER TABLE categories CHANGE Foto img varchar(100) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT "";

DROP TABLE catalogo_categorias;
