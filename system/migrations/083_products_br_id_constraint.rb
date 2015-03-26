Sequel.migration do
  up do
    run 'ALTER TABLE products CHANGE br_id br_id int(5) unsigned DEFAULT NULL;'
    run 'ALTER TABLE products ADD CONSTRAINT `brand_id` FOREIGN KEY (`br_id`) REFERENCES `brands` (`br_id`) ON DELETE RESTRICT;'
  end

  down do
  end
end

