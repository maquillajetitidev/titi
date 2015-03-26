Sequel.migration do
  up do
    run "ALTER TABLE products CHANGE `exact_price` `exact_price` decimal(10,5) UNSIGNED NOT NULL DEFAULT 0 after `real_markup`;"
  end

  down do
  end
end


