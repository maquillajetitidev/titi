Sequel.migration do
  change do
    rename_table :supply, :supplies
  end
end
