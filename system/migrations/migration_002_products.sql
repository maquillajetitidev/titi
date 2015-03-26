
DROP TABLE IF EXISTS credits;
ALTER TABLE catalogo_articulos DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE credits LIKE catalogo_articulos;
INSERT INTO credits (SELECT * FROM catalogo_articulos WHERE Tipo=2);
ALTER TABLE credits DROP Tipo, DROP Categoria, DROP Marca, DROP Presentacion, DROP Stock_deposito, DROP stock_granel, DROP VerPrecio , DROP VerPublico, DROP Descripcion, DROP NotasInternas, DROP PrecioPro, DROP VerListado, DROP Foto, DROP extraImg, DROP limiteStockLocal;
ALTER TABLE credits CHANGE id credit_id int(5) UNSIGNED NOT NULL AUTO_INCREMENT;
ALTER TABLE credits CHANGE Nombre description CHAR(60) NOT NULL DEFAULT "INVALID";
ALTER TABLE credits CHANGE Stock_local status CHAR(10) NOT NULL DEFAULT "INVALID";
UPDATE credits SET status = CASE status WHEN "0" THEN "used" ELSE "valid" END;
UPDATE credits SET Precio=Precio*-1;
ALTER TABLE credits CHANGE Precio ammount DECIMAL(6,2) UNSIGNED NOT NULL DEFAULT 0;
#DESCRIBE credits;
#SELECT * from credits;


DROP TABLE IF EXISTS log_behaviours;
DROP TABLE IF EXISTS items;

DROP TABLE IF EXISTS products;
CREATE TABLE products LIKE catalogo_articulos;
INSERT INTO products (SELECT * FROM catalogo_articulos WHERE Tipo=1);
ALTER TABLE products DROP Tipo, DROP Stock_granel;
ALTER TABLE products CHANGE id p_id int(5) UNSIGNED NOT NULL AUTO_INCREMENT;
ALTER TABLE products CHANGE Categoria c_id tinyint(4) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE products CHANGE Nombre p_name VARCHAR(196) NOT NULL DEFAULT "INVALID";

ALTER TABLE products CHANGE marca brand VARCHAR(50) NOT NULL DEFAULT "INVALID";


ALTER TABLE products ADD COLUMN brand_id tinyint(4) UNSIGNED NOT NULL DEFAULT 0 AFTER `brand`;


ALTER TABLE products CHANGE Presentacion packaging VARCHAR(50) NOT NULL DEFAULT "INVALID";
ALTER TABLE products CHANGE Stock_local stock_store_1 INT(4) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE products CHANGE limiteStockLocal ideal_stock_store_1 INT(4) UNSIGNED NOT NULL DEFAULT 5;
ALTER TABLE products CHANGE Stock_deposito stock_warehouse_1 INT(4) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE products ADD COLUMN stock_warehouse_2 INT(4) UNSIGNED NOT NULL DEFAULT 0 AFTER stock_warehouse_1;
ALTER TABLE products ADD COLUMN cost DECIMAL(6,2) UNSIGNED NOT NULL DEFAULT 0 AFTER stock_warehouse_2;
ALTER TABLE products ADD COLUMN markup DECIMAL(5,3) UNSIGNED NOT NULL DEFAULT 0 AFTER cost;

ALTER TABLE products CHANGE Precio price DECIMAL(6,2) UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE products CHANGE PrecioPro price_pro DECIMAL(6,2) UNSIGNED NOT NULL DEFAULT 0;



ALTER TABLE products CHANGE VerPublico is_published tinyint(1) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE products CHANGE VerPrecio price_is_published tinyint(1) UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE products CHANGE VerListado can_be_sold tinyint(1) UNSIGNED NOT NULL DEFAULT 0;
UPDATE products set notasInternas=replace(notasInternas, '\r\n', ' ');


UPDATE products SET notasInternas="" WHERE notasInternas IS NULL;
ALTER TABLE products CHANGE notasInternas notes TEXT NOT NULL;


ALTER TABLE products CHANGE Descripcion description TEXT NOT NULL ;
ALTER TABLE products CHANGE Foto img varchar(100)  NOT NULL DEFAULT "";
UPDATE products SET extraImg="" WHERE extraImg IS NULL;
ALTER TABLE products CHANGE extraImg img_extra varchar(100) NOT NULL DEFAULT "";

#DESCRIBE products;
#SHOW CREATE TABLE products \G
#SELECT * FROM products PROCEDURE ANALYSE()\G
#SELECT * FROM products LIMIT 1 \G


DROP TABLE catalogo_articulos;
