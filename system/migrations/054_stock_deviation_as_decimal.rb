Sequel.migration do
  up do
    run "ALTER TABLE products MODIFY COLUMN stock_deviation Decimal(6,2) default 0 NOT NULL"
  end

  down do
  end
end


