Sequel.migration do
  change do
    run '
      ALTER TABLE products CHANGE ideal_stock_store_1 ideal_stock int(4) unsigned NOT NULL DEFAULT 0;
    '
  end
end

