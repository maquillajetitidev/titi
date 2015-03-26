drop table if exists  users;

 CREATE TABLE `users` (
 `user_id` int(5) unsigned NOT NULL AUTO_INCREMENT,
 `username` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
 `user_real_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
 `user_email` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
 `level_1` tinyint(1) unsigned NOT NULL DEFAULT '0',
 `level_2` tinyint(1) unsigned NOT NULL DEFAULT '0',
 `level_3` tinyint(1) unsigned NOT NULL DEFAULT '0',
 `is_active` tinyint(1) unsigned NOT NULL DEFAULT '0',
 `session_length` smallint(5) NOT NULL DEFAULT '900',
 `password` char(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pepper',
 PRIMARY KEY (`user_id`),
 UNIQUE KEY `username` (`username`),
 UNIQUE KEY `user_email` (`user_email`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO  users (username, user_email, password) VALUES ("system", "root@maquillajetiti.com.ar", "You can\'t be me");
INSERT INTO  users (username, user_email, password) VALUES ("aburone", "correo@arielburone.com.ar", "$2a$10$l1MLSp6gZvxX263Z9cxZnOHuaB5XdwaNtmL3819w/U/mov5uRKysu");
INSERT INTO  users (username, user_email, password) VALUES ("juan", "admin@maquillajetiti.com.ar", "$2a$10$l1MLSp6gZvxX263Z9cxZnOHuaB5XdwaNtmL3819w/U/mov5uRKysu");

INSERT INTO  users (username, user_email, password) VALUES ("cristina", "ventas@maquillajetiti.com.ar", "$2a$10$l1MLSp6gZvxX263Z9cxZnOHuaB5XdwaNtmL3819w/U/mov5uRKysu");
INSERT INTO  users (username, user_email, password) VALUES ("haydee", "info@maquillajetiti.com.ar", "$2a$10$l1MLSp6gZvxX263Z9cxZnOHuaB5XdwaNtmL3819w/U/mov5uRKysu");
INSERT INTO  users (username, user_email, password) VALUES ("veronica", "produccion@maquillajetiti.com.ar", "$2a$10$l1MLSp6gZvxX263Z9cxZnOHuaB5XdwaNtmL3819w/U/mov5uRKysu");


 -- `is_mechanic` tinyint(1) NOT NULL DEFAULT '0',
 -- `is_dangerous` tinyint(1) NOT NULL DEFAULT '0',
 -- `can_mass_edit_products` tinyint(1) NOT NULL DEFAULT '0',
 -- `can_upload_pictures` tinyint(1) NOT NULL DEFAULT '0',
 -- `can_add_arbitrary` tinyint(1) NOT NULL DEFAULT '0',
 -- `hash_iterations` smallint(5) unsigned NOT NULL DEFAULT '0',
 -- `salt` binary(60) NOT NULL DEFAULT 'salt ٩๏̯͡๏)۶ ლʕಠᴥಠʔლ',
 -- `can_edit_products` tinyint(1) NOT NULL DEFAULT '0',
 -- `can_modify_stock` tinyint(1) NOT NULL DEFAULT '0',
