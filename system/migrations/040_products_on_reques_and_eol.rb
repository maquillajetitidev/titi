Sequel.migration do
  up do
    run "ALTER TABLE products ADD `on_request` tinyint(1) UNSIGNED NOT NULL DEFAULT 0 after `tercerized`"
    run "ALTER TABLE products ADD `end_of_life` tinyint(1) UNSIGNED NOT NULL DEFAULT 0 after `on_request`"
    run "ALTER TABLE products change `archived` `archived` tinyint(1) UNSIGNED NOT NULL DEFAULT 0 after `end_of_life`"
  end

  down do
    drop_column :products, :on_request
    drop_column :products, :end_of_life
  end
end
