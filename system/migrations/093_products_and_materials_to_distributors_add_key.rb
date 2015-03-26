Sequel.migration do
  up do
    run 'ALTER TABLE products_to_distributors ADD ptd_id int unsigned NOT NULL PRIMARY KEY AUTO_INCREMENT'

    run 'ALTER TABLE materials_to_distributors ADD mtd_id  int unsigned NOT NULL PRIMARY KEY AUTO_INCREMENT'
  end

  down do
  end
end



