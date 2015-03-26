Sequel.migration do
  up do
    run "
      CREATE TABLE `accounts_transactions` (
        `t_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
        `t_desc` char(100) NOT NULL,
        `created_at` datetime DEFAULT NULL,

        PRIMARY KEY (`t_id`),
        KEY `created_at` (`created_at`)
      )
    "
    run '
      CREATE TRIGGER at_init BEFORE INSERT ON `accounts_transactions`
      FOR EACH ROW SET
      NEW.created_at = IFNULL(NEW.created_at, NOW());
    '

    run "
      CREATE TABLE `accounts_records` (
        `r_id` int(10) unsigned NOT NULL AUTO_INCREMENT,

        `t_id` int(10) unsigned NOT NULL,
        `r_loc` char(12) NOT NULL DEFAULT 'UNDEFINED',
        `r_orig` char(50) NOT NULL,
        `r_dest` char(50) NOT NULL,
        `r_amount` decimal(8,2) NOT NULL DEFAULT '0.00',

        `o_id` int(5) unsigned NOT NULL DEFAULT '0',

        PRIMARY KEY (`r_id`),
        KEY `t_id` (`t_id`),
        KEY `r_loc` (`r_loc`),
        KEY `r_orig` (`r_orig`),
        KEY `r_dest` (`r_dest`),
        CONSTRAINT `t_id` FOREIGN KEY (`t_id`) REFERENCES `accounts_transactions` (`t_id`)
      )
    "

  end

  down do
    drop_table :accounts_records
    drop_table :accounts_transactions
  end
end




