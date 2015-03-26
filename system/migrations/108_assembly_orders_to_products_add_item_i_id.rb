Sequel.migration do
  up do
    run 'ALTER TABLE assembly_orders_to_products ADD i_id char(17) AFTER p_id'
    run 'ALTER TABLE assembly_orders_to_products ADD CONSTRAINT `aotp_i_id` FOREIGN KEY (`i_id`) REFERENCES `items` (`i_id`) ON DELETE RESTRICT'
  end
end
