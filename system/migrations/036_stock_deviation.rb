Sequel.migration do
  up do
    run 'ALTER TABLE products ADD stock_deviation int(10) NOT NULL default 0 after ideal_stock'
  end

  down do
  end
end
