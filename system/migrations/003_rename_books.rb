Sequel.migration do
  change do
    rename_table :books, :book_records
  end
end