Sequel.migration do
  up do
    run '
      CREATE TABLE `parts_to_assemblies` (
        `pta_id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT,
        `o_id` int(5) UNSIGNED NOT NULL,

        `part_id` char(17) NOT NULL,
        `part_prod_id` int(5) UNSIGNED NOT NULL,

        `assembly_id` char(17) NOT NULL,
        `assembly_prod_id` int(5) UNSIGNED NOT NULL,

        `created_at` datetime DEFAULT NULL,

       PRIMARY KEY (`pta_id`),
       KEY `pta_part_id` (`part_id`),
       KEY `pta_part_prod_id` (`part_prod_id`),
       KEY `pta_assembly_id` (`assembly_id`),
       KEY `pta_assembly_prod_id` (`assembly_prod_id`),
       CONSTRAINT `pta_part_id` FOREIGN KEY (`part_id`) REFERENCES `items` (`i_id`) ON DELETE RESTRICT,
       CONSTRAINT `pta_part_prod_id` FOREIGN KEY (`part_prod_id`) REFERENCES `products` (`p_id`) ON DELETE RESTRICT,

       CONSTRAINT `pta_assembly_id` FOREIGN KEY (`assembly_id`) REFERENCES `items` (`i_id`) ON DELETE RESTRICT,
       CONSTRAINT `pta_assembly_prod_id` FOREIGN KEY (`assembly_prod_id`) REFERENCES `products` (`p_id`) ON DELETE RESTRICT
       ) ENGINE=InnoDB  ROW_FORMAT=DYNAMIC;
    '

    run '
      CREATE TRIGGER parts_to_assemblies_init BEFORE INSERT ON `parts_to_assemblies`
        FOR EACH ROW SET
        NEW.created_at = IFNULL(NEW.created_at, NOW());
    '
  end
end
