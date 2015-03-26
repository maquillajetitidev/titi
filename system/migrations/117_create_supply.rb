Sequel.migration do
  up do
    run "
      CREATE TABLE `supply` (
        `p_id` int(5) unsigned NOT NULL,

        `s1_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s1_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s1_part` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s1_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s1` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_future` int(4) unsigned NOT NULL DEFAULT '0',
        `s1_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s1_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `s2_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s2_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s2_part` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s2_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s2` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_future` int(4) unsigned NOT NULL DEFAULT '0',
        `s2_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `s2_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `stores_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `stores_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `stores_part` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `stores_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `stores` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_future` int(4) unsigned NOT NULL DEFAULT '0',
        `stores_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `stores_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `w1_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w1_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w1_part` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w1_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w1` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_future` int(4) unsigned NOT NULL DEFAULT '0',
        `w1_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w1_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `w2_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w2_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w2_part` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w2_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w2` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_future` int(4) unsigned NOT NULL DEFAULT '0',
        `w2_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `w2_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `wharehouses_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `wharehouses_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `wharehouses_part` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `wharehouses_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `wharehouses` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_future` int(4) unsigned NOT NULL DEFAULT '0',
        `wharehouses_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `wharehouses_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `global_whole` int(4) unsigned NOT NULL DEFAULT '0',
        `global_whole_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `global_whole_future` int(4) unsigned NOT NULL DEFAULT '0',
        `global_whole_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `global_whole_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `global_part` int(4) unsigned NOT NULL DEFAULT '0',
        `global_part_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `global_part_future` int(4) unsigned NOT NULL DEFAULT '0',
        `global_part_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `global_part_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',
        `global` int(4) unsigned NOT NULL DEFAULT '0',
        `global_en_route` int(4) unsigned NOT NULL DEFAULT '0',
        `global_future` int(4) unsigned NOT NULL DEFAULT '0',
        `global_ideal` decimal(6,2) NOT NULL DEFAULT '0.00',
        `global_deviation` decimal(6,2) NOT NULL DEFAULT '0.00',

        `updated_at` datetime DEFAULT NULL,
        PRIMARY KEY (`p_id`),
        CONSTRAINT `c_p_id` FOREIGN KEY (`p_id`) REFERENCES `products` (`p_id`)
        )
    "

    run '
      CREATE TRIGGER s_update BEFORE UPDATE ON `supply`
        FOR EACH ROW BEGIN
          SET NEW.updated_at = NOW();
        END
    '

  end

end


