Sequel.migration do
  up do
    run "ALTER TABLE orders MODIFY COLUMN type char(13) NOT NULL DEFAULT 'UNDEFINED'"
  end

  down do
    run "ALTER TABLE orders MODIFY COLUMN type char(12) NOT NULL DEFAULT 'UNDEFINED'"
  end
end
