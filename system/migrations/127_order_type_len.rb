Sequel.migration do
  change do
    run "ALTER TABLE orders MODIFY COLUMN type char(14) NOT NULL DEFAULT 'UNDEFINED'"
  end
end
