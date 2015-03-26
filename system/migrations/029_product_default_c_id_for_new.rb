Sequel.migration do
  up do
    run 'ALTER TABLE products CHANGE `c_id` `c_id` int(5) unsigned NOT NULL DEFAULT 1;'
  end

  down do
  end
end
