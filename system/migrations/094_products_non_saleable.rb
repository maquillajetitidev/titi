Sequel.migration do
  up do
    run "ALTER TABLE products ADD `non_saleable` tinyint(1) UNSIGNED NOT NULL DEFAULT 0 after `on_request`"
  end

  down do
    drop_column :products, :non_saleable
  end
end
