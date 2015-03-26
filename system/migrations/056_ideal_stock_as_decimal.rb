Sequel.migration do
  up do
    run "ALTER TABLE products MODIFY COLUMN ideal_stock Decimal(6,2) default 0 NOT NULL"
  end

  down do
  end
end


