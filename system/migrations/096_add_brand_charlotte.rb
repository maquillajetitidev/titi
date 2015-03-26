Sequel.migration do
  up do
    run 'INSERT INTO brands (br_name) VALUES ("Charlotte");'
  end

  down do
    run 'DELETE FROM brands  WHERE br_name = "Charlotte";'
  end
end
